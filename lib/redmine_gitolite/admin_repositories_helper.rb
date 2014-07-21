module RedmineGitolite

  module AdminRepositoriesHelper

    def handle_repository_add(repository, opts = {})
      force = (opts.has_key?(:force) && opts[:force] == true) || false
      old_perms = (opts.has_key?(:old_perms) && opts[:old_perms].is_a?(Hash)) ? opts[:old_perms] : {}

      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
      repo_conf = @gitolite_config.repos[repo_name]

      if !repo_conf
        logger.info { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, create it ..." }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        old_permissions = old_perms
      else
        if force
          logger.warn { "#{@action} : repository '#{repo_name}' already exists in Gitolite, force mode !" }
          logger.debug { "#{@action} : repository path '#{repo_path}'" }
          old_permissions = get_old_permissions(repo_conf)
          @gitolite_config.rm_repo(repo_name)
        else
          logger.warn { "#{@action} : repository '#{repo_name}' already exists in Gitolite, exit !" }
          logger.debug { "#{@action} : repository path '#{repo_path}'" }
          return false
        end
      end

      do_update_repository(repository, old_permissions)
    end


    def handle_repository_update(repository)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
      repo_conf = @gitolite_config.repos[repo_name]

      if repo_conf
        logger.info { "#{@action} : repository '#{repo_name}' exists in Gitolite, update it ..." }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        old_perms = get_old_permissions(repo_conf)
        @gitolite_config.rm_repo(repo_name)
      else
        logger.warn { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        return false
      end

      do_update_repository(repository, old_perms)
    end


    def handle_repository_delete(repository_data)
      repo_name = repository_data['repo_name']
      repo_path = repository_data['repo_path']
      repo_conf = @gitolite_config.repos[repo_name]

      if !repo_conf
        logger.warn { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        return false
      else
        logger.info { "#{@action} : repository '#{repo_name}' exists in Gitolite, delete it ..." }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        @gitolite_config.rm_repo(repo_name)
      end
    end


    def handle_repositories_move(project)
      projects = project.self_and_descendants

      # Only take projects that have Git repos.
      git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}
      return if git_projects.empty?

      git_projects.reverse.each do |project|
        repo_list = []

        project.gitolite_repos.reverse.each do |repository|
          repo_list.push(repository.gitolite_repository_name)
          do_move_repositories(repository)
        end

        gitolite_admin_repo_commit("#{@action} : #{project.identifier} | #{repo_list}")
      end
    end


    def do_update_repository(repository, old_permissions)
      repo_name = repository.gitolite_repository_name
      repo_conf = @gitolite_config.repos[repo_name]
      project   = repository.project

      # Create new repo object
      repo_conf = Gitolite::Config::Repo.new(repo_name)

      # Set post-receive hook params
      repo_conf.set_git_config("redminegitolite.projectid", repository.project.identifier.to_s)
      repo_conf.set_git_config("redminegitolite.repositoryid", "#{repository.identifier || ''}")
      repo_conf.set_git_config("redminegitolite.repositorykey", repository.extra.key)

      if project.active?
        if User.anonymous.allowed_to?(:view_changesets, project) || repository.extra.git_http != 0
          repo_conf.set_git_config("http.uploadpack", 'true')
        else
          repo_conf.set_git_config("http.uploadpack", 'false')
        end

        # Set mail-notifications hook params
        mailing_list = repository.mailing_list_params[:mailing_list]

        if repository.extra.git_notify == 1 && !mailing_list.empty?
          email_prefix   = repository.mailing_list_params[:email_prefix]
          sender_address = repository.mailing_list_params[:sender_address]

          repo_conf.set_git_config("multimailhook.enabled", 'true')
          repo_conf.set_git_config("multimailhook.environment", "gitolite")
          repo_conf.set_git_config("multimailhook.mailinglist", mailing_list.keys.join(", "))
          repo_conf.set_git_config("multimailhook.from", sender_address)
          repo_conf.set_git_config("multimailhook.emailPrefix", email_prefix)

          # Set SMTP server for mail-notifications hook
          #~ repo_conf.set_git_config("multimailhook.smtpServer", ActionMailer::Base.smtp_settings[:address])
        else
          repo_conf.set_git_config("multimailhook.enabled", 'false')
        end

        # Set Git config keys
        if repository.repository_git_config_keys.any?
          repository.repository_git_config_keys.each do |git_config_key|
            repo_conf.set_git_config(git_config_key.key, git_config_key.value)
          end
        end
      else
        repo_conf.set_git_config("http.uploadpack", 'false')
        repo_conf.set_git_config("multimailhook.enabled", 'false')
      end

      @gitolite_config.add_repo(repo_conf)

      current_permissions = build_permissions(repository)
      current_permissions = merge_permissions(current_permissions, old_permissions)

      repo_conf.permissions = [current_permissions]
    end


    def do_move_repositories(repository)
      repo_id   = repository.redmine_name
      repo_name = repository.old_repository_name

      repo_conf = @gitolite_config.repos[repo_name]

      old_repo_name = repository.old_repository_name
      new_repo_name = repository.new_repository_name

      old_relative_path  = repository.url
      new_relative_path  = repository.gitolite_repository_path

      old_relative_parent_path = old_relative_path.gsub(repo_id + '.git', '')
      new_relative_parent_path = new_relative_path.gsub(repo_id + '.git', '')

      logger.info { "#{@action} : Moving '#{repo_name}'..." }
      logger.debug { "  Old repository name (for Gitolite)           : #{old_repo_name}" }
      logger.debug { "  New repository name (for Gitolite)           : #{new_repo_name}" }
      logger.debug { "-----" }
      logger.debug { "  Old relative path (for Redmine code browser) : #{old_relative_path}" }
      logger.debug { "  New relative path (for Redmine code browser) : #{new_relative_path}" }
      logger.debug { "-----" }
      logger.debug { "  Old relative parent path (for Gitolite)      : #{old_relative_parent_path}" }
      logger.debug { "  New relative parent path (for Gitolite)      : #{new_relative_parent_path}" }

      if !repo_conf
        logger.error { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
        return false
      else
        if move_physical_repo(old_relative_path, new_relative_path, new_relative_parent_path)
          @delete_parent_path.push(old_relative_parent_path)

          repository.update_column(:url, new_relative_path)
          repository.update_column(:root_url, new_relative_path)

          # update gitolite conf
          old_perms = get_old_permissions(repo_conf)
          @gitolite_config.rm_repo(old_repo_name)
          handle_repository_add(repository, :force => true, :old_perms => old_perms)
        else
          return false
        end
      end

    end


    SKIP_USERS = [ 'gitweb', 'daemon', 'DUMMY_REDMINE_KEY', 'REDMINE_ARCHIVED_PROJECT', 'REDMINE_CLOSED_PROJECT' ]

    def get_old_permissions(repo_conf)
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
            next if @gitolite_identifier_prefix == ''

            # ignore these users
            next if SKIP_USERS.include?(user)

            # backup users that are not Redmine users
            if !user.include?(@gitolite_identifier_prefix)
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

      rewind_users = users.select{|user| user.allowed_to?(:manage_repository, project)}
      write_users  = users.select{|user| user.allowed_to?(:commit_access, project)} - rewind_users
      read_users   = users.select{|user| user.allowed_to?(:view_changesets, project)} - rewind_users - write_users

      if project.active?
        rewind = rewind_users.map{|user| user.gitolite_identifier}
        write  = write_users.map{|user| user.gitolite_identifier}
        read   = read_users.map{|user| user.gitolite_identifier}

        ## DEPLOY KEY
        deploy_keys = repository.repository_deployment_credentials.active

        if deploy_keys.any?
          deploy_keys.each do |cred|
            if cred.perm == "RW+"
              rewind << cred.gitolite_public_key.owner
            elsif cred.perm == "R"
              read << cred.gitolite_public_key.owner
            end
          end
        end

        read << "DUMMY_REDMINE_KEY" if read.empty? && write.empty? && rewind.empty?
        read << "gitweb" if User.anonymous.allowed_to?(:browse_repository, project) && repository.extra.git_http != 0
        read << "daemon" if User.anonymous.allowed_to?(:view_changesets, project) && repository.extra.git_daemon == 1
      elsif project.archived?
        read << "REDMINE_ARCHIVED_PROJECT"
      else
        all_read = rewind_users + write_users + read_users
        read     = all_read.map{|user| user.gitolite_identifier}
        read << "REDMINE_CLOSED_PROJECT" if read.empty?
      end

      permissions = {}
      permissions["RW+"] = {"" => rewind.uniq.sort} unless rewind.empty?
      permissions["RW"] = {"" => write.uniq.sort} unless write.empty?
      permissions["R"] = {"" => read.uniq.sort} unless read.empty?

      permissions
    end


    def clean_path(path_list)
      path_list.uniq.sort.reverse.each do |path|
        begin
          logger.info { "#{@action} : cleaning repository path : '#{path}'" }
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rmdir '#{path}' 2>/dev/null || true")
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "#{@action} : error while cleaning repository path '#{path}'" }
        end
      end
    end


    def is_repository_empty?(new_path)
      empty_repo = false

      begin
        output = RedmineGitolite::GitHosting.execute_command(:shell_cmd, "find '#{new_path}/objects' -type f | wc -l").chomp.gsub('\n', '')
        logger.debug { "#{@action} : counted objects in repository directory '#{new_path}' : '#{output}'" }

        if output.to_i == 0
          empty_repo = true
        else
          empty_repo = false
        end
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        empty_repo = false
      end

      return empty_repo
    end


    def move_physical_repo(old_path, new_path, new_parent_path)
      ## CASE 0
      if old_path == new_path
        logger.info { "#{@action} : old repository and new repository are identical '#{old_path}', nothing to do, exit !" }
        return true
      end

      ## CASE 1
      if RedmineGitolite::GitHosting.file_exists?(new_path) && RedmineGitolite::GitHosting.file_exists?(old_path)

        if is_repository_empty?(new_path)
          logger.warn { "#{@action} : target repository '#{new_path}' already exists and is empty, remove it ..." }
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{new_path}'")
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "#{@action} : removing existing target repository failed, exit !" }
            return false
          end
        else
          logger.warn { "#{@action} : target repository '#{new_path}' exists and is not empty, considered as already moved, try to remove the old_path" }

          if is_repository_empty?(old_path)
            begin
              RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{old_path}'")
              return true
            rescue RedmineGitolite::GitHosting::GitHostingException => e
              logger.error { "#{@action} : removing source repository directory failed, exit !" }
              return false
            end
          else
            logger.error { "#{@action} : the source repository directory is not empty, cannot remove it, exit ! (This repo will be orphan)" }
            return false
          end
        end

      ## CASE 2
      elsif !RedmineGitolite::GitHosting.file_exists?(new_path) && !RedmineGitolite::GitHosting.file_exists?(old_path)
        logger.error { "#{@action} : both old repository '#{old_path}' and new repository '#{new_path}' does not exist, cannot move it, exit but let Gitolite create the new repo !" }
        return true

      ## CASE 3
      elsif RedmineGitolite::GitHosting.file_exists?(new_path) && !RedmineGitolite::GitHosting.file_exists?(old_path)
        logger.error { "#{@action} : old repository '#{old_path}' does not exist, but the new one does, use it !" }
        return true

      ## CASE 4
      elsif !RedmineGitolite::GitHosting.file_exists?(new_path) && RedmineGitolite::GitHosting.file_exists?(old_path)

        logger.debug { "#{@action} : really moving Gitolite repository from '#{old_path}' to '#{new_path}'" }

        if !RedmineGitolite::GitHosting.file_exists? new_parent_path
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mkdir -p '#{new_parent_path}'")
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "#{@action} : creation of parent path '#{new_parent_path}' failed, exit !" }
            return false
          end
        end

        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mv '#{old_path}' '#{new_path}'")
          logger.info { "#{@action} : done !" }
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "move_physical_repo(#{old_path}, #{new_path}) failed" }
          return false
        end
      end
    end


    def create_readme_file(repository)
      logger.info { "Create README file for repository '#{repository.gitolite_repository_name}'"}

      temp_dir = Dir.mktmpdir

      command = ""
      command << "env GIT_SSH=#{RedmineGitolite::Config.gitolite_admin_ssh_script_path} git clone #{repository.ssh_url} #{temp_dir} >/dev/null 2>&1"
      command << " && cd #{temp_dir}"
      command << " && echo '## #{repository.gitolite_repository_name}' >> README.md"
      command << " && git add README.md"
      command << " && git commit README.md -m 'Initialize repository' --author='#{RedmineGitolite::Config.gitolite_commit_author}'"
      command << " && env GIT_SSH=#{RedmineGitolite::Config.gitolite_admin_ssh_script_path} git push -u origin master"

      begin
        output = RedmineGitolite::GitHosting.execute_command(:local_cmd, command)
        logger.info { "README file successfully created for repository '#{repository.gitolite_repository_name}'"}
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while creating README file for repository '#{repository.gitolite_repository_name}'"}
        logger.error { e.output }
      end

      FileUtils.remove_entry temp_dir rescue ''
    end


    def delete_hook_param(repository, parameter_name)
      begin
        RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{repository.gitolite_repository_path}' config --local --unset #{parameter_name}")
        logger.info { "Git config key '#{parameter_name}' successfully deleted for repository '#{repository.gitolite_repository_name}'"}
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while deleting Git config key '#{parameter_name}' for repository '#{repository.gitolite_repository_name}'"}
      end
    end


    def delete_hook_section(repository, section_name)
      begin
        RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{repository.gitolite_repository_path}' config --local --remove-section #{section_name} || true")
        logger.info { "Git config section '#{section_name}' successfully deleted for repository '#{repository.gitolite_repository_name}'"}
      rescue RedmineGitolite::GitHosting::GitHostingException => e
        logger.error { "Error while deleting Git config section '#{section_name}' for repository '#{repository.gitolite_repository_name}'"}
      end
    end


  end
end
