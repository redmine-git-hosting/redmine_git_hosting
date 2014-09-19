require 'rugged'

module RedmineGitolite

  module GitoliteWrapper

    module RepositoriesHelper

      def handle_repository_add(repository, opts = {})
        force = (opts.has_key?(:force) && opts[:force] == true) || false
        old_perms = (opts.has_key?(:old_perms) && opts[:old_perms].is_a?(Hash)) ? opts[:old_perms] : {}

        repo_name = repository.gitolite_repository_name
        repo_path = repository.gitolite_repository_path
        repo_conf = gitolite_config.repos[repo_name]

        if !repo_conf
          logger.info { "#{action} : repository '#{repo_name}' does not exist in Gitolite, create it ..." }
          logger.debug { "#{action} : repository path '#{repo_path}'" }
          old_permissions = old_perms
        else
          if force
            logger.warn { "#{action} : repository '#{repo_name}' already exists in Gitolite, force mode !" }
            logger.debug { "#{action} : repository path '#{repo_path}'" }
            old_permissions = get_old_permissions(repo_conf)
            gitolite_config.rm_repo(repo_name)
          else
            logger.warn { "#{action} : repository '#{repo_name}' already exists in Gitolite, exit !" }
            logger.debug { "#{action} : repository path '#{repo_path}'" }
            return false
          end
        end

        do_update_repository(repository, old_permissions)
      end


      def handle_repository_update(repository)
        repo_name = repository.gitolite_repository_name
        repo_path = repository.gitolite_repository_path
        repo_conf = gitolite_config.repos[repo_name]

        if repo_conf
          logger.info { "#{action} : repository '#{repo_name}' exists in Gitolite, update it ..." }
          logger.debug { "#{action} : repository path '#{repo_path}'" }
          old_perms = get_old_permissions(repo_conf)
          gitolite_config.rm_repo(repo_name)
        else
          logger.warn { "#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
          logger.debug { "#{action} : repository path '#{repo_path}'" }
          return false
        end

        do_update_repository(repository, old_perms)
      end


      def handle_repository_delete(repository_data)
        repo_name = repository_data['repo_name']
        repo_path = repository_data['repo_path']
        repo_conf = gitolite_config.repos[repo_name]

        if !repo_conf
          logger.warn { "#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
          logger.debug { "#{action} : repository path '#{repo_path}'" }
          return false
        else
          logger.info { "#{action} : repository '#{repo_name}' exists in Gitolite, delete it ..." }
          logger.debug { "#{action} : repository path '#{repo_path}'" }
          gitolite_config.rm_repo(repo_name)
        end
      end


      def do_update_repository(repository, old_permissions)
        repo_name = repository.gitolite_repository_name
        repo_conf = gitolite_config.repos[repo_name]
        project   = repository.project

        # Create new repo object
        repo_conf = Gitolite::Config::Repo.new(repo_name)

        # Set post-receive hook params
        repo_conf.set_git_config("redminegitolite.projectid", repository.project.identifier.to_s)
        repo_conf.set_git_config("redminegitolite.repositoryid", "#{repository.identifier || ''}")
        repo_conf.set_git_config("redminegitolite.repositorykey", repository.extra[:key])

        if project.active?
          if User.anonymous.allowed_to?(:view_changesets, project) || repository.extra[:git_http] != 0
            repo_conf.set_git_config("http.uploadpack", 'true')
          else
            repo_conf.set_git_config("http.uploadpack", 'false')
          end

          # Set mail-notifications hook params
          repo_conf = set_mail_settings(repository, repo_conf)

          # Set Git config keys
          if repository.git_config_keys.any?
            repository.git_config_keys.each do |git_config_key|
              repo_conf.set_git_config(git_config_key.key, git_config_key.value)
            end
          end
        else
          repo_conf.set_git_config("http.uploadpack", 'false')
          repo_conf.set_git_config("multimailhook.enabled", 'false')
        end

        gitolite_config.add_repo(repo_conf)

        current_permissions = build_permissions(repository)
        current_permissions = merge_permissions(current_permissions, old_permissions)

        repo_conf.permissions = [current_permissions]
      end


      def set_mail_settings(repository, repo_conf)
        notifier = ::GitNotifier.new(repository)

        if repository.extra[:git_notify] && !notifier.mailing_list.empty?
          repo_conf.set_git_config("multimailhook.enabled", 'true')
          repo_conf.set_git_config("multimailhook.mailinglist", notifier.mailing_list.join(", "))
          repo_conf.set_git_config("multimailhook.from", notifier.sender_address)
          repo_conf.set_git_config("multimailhook.emailPrefix", notifier.email_prefix)
        else
          repo_conf.set_git_config("multimailhook.enabled", 'false')
        end

        return repo_conf
      end


      SKIP_USERS = [ 'gitweb', 'daemon', 'DUMMY_REDMINE_KEY', 'REDMINE_ARCHIVED_PROJECT', 'REDMINE_CLOSED_PROJECT' ]

      def get_old_permissions(repo_conf)
        gitolite_identifier_prefix = RedmineGitolite::Config.get_setting(:gitolite_identifier_prefix)

        current_permissions = repo_conf.permissions[0]
        old_permissions = {}

        current_permissions.each do |perm, branch_settings|
          old_permissions[perm] = {}

          branch_settings.each do |branch, user_list|
            next if user_list.empty?

            new_user_list = []

            user_list.each do |user|
              ## We assume here that ':gitolite_config_file' is different than 'gitolite.conf'
              ## like 'redmine.conf' with 'include "redmine.conf"' in 'gitolite.conf'.
              ## This way, we know that all repos in this file are managed by Redmine so we
              ## don't need to backup users
              next if gitolite_identifier_prefix == ''

              # ignore these users
              next if SKIP_USERS.include?(user)

              # backup users that are not Redmine users
              if !user.include?(gitolite_identifier_prefix)
                new_user_list.push(user)
              end
            end

            if new_user_list.any?
              old_permissions[perm][branch] = new_user_list
            end
          end
        end

        return old_permissions
      end


      def merge_permissions(current_permissions, old_permissions)
        merge_permissions = {}
        merge_permissions['RW+'] = {}
        merge_permissions['RW'] = {}
        merge_permissions['R'] = {}

        current_permissions.each do |perm, branch_settings|
          branch_settings.each do |branch, user_list|
            if user_list.any?
              if !merge_permissions[perm].has_key?(branch)
                merge_permissions[perm][branch] = []
              end
              merge_permissions[perm][branch] += user_list
            end
          end
        end

        old_permissions.each do |perm, branch_settings|
          branch_settings.each do |branch, user_list|
            if user_list.any?
              if !merge_permissions[perm].has_key?(branch)
                merge_permissions[perm][branch] = []
              end
              merge_permissions[perm][branch] += user_list
            end
          end
        end

        merge_permissions.each do |perm, branch_settings|
          merge_permissions.delete(perm) if merge_permissions[perm].empty?
        end

        return merge_permissions
      end


      def build_permissions(repository)
        users   = repository.project.member_principals.map(&:user).compact.uniq
        project = repository.project

        rewind = []
        write  = []
        read   = []

        rewind_users   = users.select{|user| user.allowed_to?(:manage_repository, project)}
        write_users    = users.select{|user| user.allowed_to?(:commit_access, project)} - rewind_users
        read_users     = users.select{|user| user.allowed_to?(:view_changesets, project)} - rewind_users - write_users

        if project.active?
          rewind = rewind_users.map{|user| user.gitolite_identifier}.sort
          write  = write_users.map{|user| user.gitolite_identifier}.sort
          read   = read_users.map{|user| user.gitolite_identifier}.sort
          developer_team = rewind + write

          ## DEPLOY KEY
          repository.deployment_credentials.active.each do |cred|
            if cred.perm == "RW+"
              rewind << cred.gitolite_public_key.owner
            elsif cred.perm == "R"
              read << cred.gitolite_public_key.owner
            end
          end

          read << "DUMMY_REDMINE_KEY" if read.empty? && write.empty? && rewind.empty?
          read << "gitweb" if User.anonymous.allowed_to?(:browse_repository, project) && repository.extra[:git_http] != 0
          read << "daemon" if User.anonymous.allowed_to?(:view_changesets, project) && repository.extra[:git_daemon]
        elsif project.archived?
          read << "REDMINE_ARCHIVED_PROJECT"
        else
          all_read = rewind_users + write_users + read_users
          read     = all_read.map{|user| user.gitolite_identifier}
          read << "REDMINE_CLOSED_PROJECT"
        end

        permissions = {}
        permissions["RW+"] = {}
        permissions["RW"] = {}
        permissions["R"] = {}

        if repository.extra[:protected_branch]
          ## http://gitolite.com/gitolite/rules.html
          ## The refex field is ignored for read check.
          ## (Git does not support distinguishing one ref from another for access control during read operations).

          repository.protected_branches.each do |branch|
            case branch.permissions
              when 'RW+'
                permissions["RW+"][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
              when 'RW'
                permissions["RW"][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
            end
          end

          permissions["RW+"]['personal/USER/'] = developer_team.sort unless developer_team.empty?
        end

        permissions["RW+"][""] = rewind unless rewind.empty?
        permissions["RW"][""] = write unless write.empty?
        permissions["R"][""] = read unless read.empty?

        permissions
      end


      def create_readme_file(repository)
        logger.info { "Create README file for repository '#{repository.gitolite_repository_name}'"}

        temp_dir = Dir.mktmpdir

        ## Create credentials object
        credentials = Rugged::Credentials::SshKey.new(
          :username   => RedmineGitolite::GitoliteWrapper.gitolite_user,
          :publickey  => RedmineGitolite::GitoliteWrapper.gitolite_ssh_public_key,
          :privatekey => RedmineGitolite::GitoliteWrapper.gitolite_ssh_private_key
        )

        commit_author = {
          :email => RedmineGitolite::GitoliteWrapper.git_config_username,
          :name  => RedmineGitolite::GitoliteWrapper.git_config_email,
          :time  => Time.now
        }

        begin
          ## Clone repository
          repo = Rugged::Repository.clone_at(repository.ssh_url, temp_dir, credentials: credentials)

          ## Create file
          oid = repo.write("## #{repository.gitolite_repository_name}", :blob)
          index = repo.index
          index.add(:path => "README.md", :oid => oid, :mode => 0100644)

          ## Create commit
          commit_tree = index.write_tree(repo)
          commit = Rugged::Commit.create(repo,
            :author     => commit_author,
            :committer  => commit_author,
            :message    => "Add README file",
            :parents    => repo.empty? ? [] : [ repo.head.target ].compact,
            :tree       => commit_tree,
            :update_ref => 'HEAD'
          )

          ## Push
          repo.push('origin', [ "refs/heads/#{repository.extra[:default_branch]}" ], credentials: credentials)
        rescue => e
          logger.error { "Error while creating README file for repository '#{repository.gitolite_repository_name}'"}
          logger.error { e.message }
        ensure
          FileUtils.rm_rf temp_dir
        end
      end


      def delete_hook_param(repository, parameter_name)
        begin
          RedmineGitolite::GitoliteWrapper.sudo_capture('git', "--git-dir=#{repository.gitolite_repository_path}", 'config', '--local', '--unset', parameter_name)
          logger.info { "Git config key '#{parameter_name}' successfully deleted for repository '#{repository.gitolite_repository_name}'"}
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while deleting Git config key '#{parameter_name}' for repository '#{repository.gitolite_repository_name}'"}
        end
      end


      def delete_hook_section(repository, section_name)
        begin
          RedmineGitolite::GitoliteWrapper.sudo_capture('git', "--git-dir=#{repository.gitolite_repository_path}", 'config', '--local', '--remove-section', section_name)
          logger.info { "Git config section '#{section_name}' successfully deleted for repository '#{repository.gitolite_repository_name}'"}
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while deleting Git config section '#{section_name}' for repository '#{repository.gitolite_repository_name}'"}
        end
      end

    end
  end
end
