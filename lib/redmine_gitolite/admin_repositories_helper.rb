module RedmineGitolite

  module AdminRepositoriesHelper

    def handle_repository_add(repository, force = false)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
      repo_conf = @gitolite_config.repos[repo_name]

      if !repo_conf
        logger.info { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, create it ..." }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
      else
        if force == true
          logger.warn { "#{@action} : repository '#{repo_name}' already exists in Gitolite, force mode !" }
          logger.debug { "#{@action} : repository path '#{repo_path}'" }
          @gitolite_config.rm_repo(repo_name)
        else
          logger.warn { "#{@action} : repository '#{repo_name}' already exists in Gitolite, exit !" }
          logger.debug { "#{@action} : repository path '#{repo_path}'" }
          return false
        end
      end

      do_update_repository(repository)
    end


    def handle_repository_update(repository)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
      repo_conf = @gitolite_config.repos[repo_name]

      if repo_conf
        logger.info { "#{@action} : repository '#{repo_name}' exists in Gitolite, update it ..." }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        @gitolite_config.rm_repo(repo_name)
      else
        logger.warn { "#{@action} : repository '#{repo_name}' does not exist in Gitolite, exit !" }
        logger.debug { "#{@action} : repository path '#{repo_path}'" }
        return false
      end

      do_update_repository(repository)
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


    def do_update_repository(repository)
      repo_name = repository.gitolite_repository_name
      repo_conf = @gitolite_config.repos[repo_name]
      project   = repository.project

      # Create new repo object
      repo_conf = Gitolite::Config::Repo.new(repo_name)

      # Set post-receive hook params
      repo_conf.set_git_config("redmineGitolite.projectId", repository.project.identifier.to_s)
      repo_conf.set_git_config("redmineGitolite.repositoryId", "#{repository.identifier || ''}")
      repo_conf.set_git_config("redmineGitolite.repositoryKey", repository.extra.key)

      if User.anonymous.allowed_to?(:view_changesets, project) && (repository.extra.git_http == 1 || repository.extra.git_http == 2)
        repo_conf.set_git_config("http.uploadpack", 'true')
      else
        repo_conf.set_git_config("http.uploadpack", 'false')
      end

      # Set mail-notifications hook params
      mailing_list = repository.mailing_list_params[:mailing_list]

      if repository.extra.git_notify == 1 && !mailing_list.empty?

        email_prefix   = repository.mailing_list_params[:email_prefix]
        sender_address = repository.mailing_list_params[:sender_address]

        repo_conf.set_git_config("multimailhook.environment", "gitolite")
        repo_conf.set_git_config("multimailhook.mailinglist", mailing_list.keys.join(", "))
        repo_conf.set_git_config("multimailhook.from", email_prefix)
        repo_conf.set_git_config("multimailhook.emailPrefix", sender_address)

        # Set SMTP server for mail-notifications hook
        #~ repo_conf.set_git_config("multimailhook.smtpServer", ActionMailer::Base.smtp_settings[:address])

      else
        repo_conf.set_git_config("multimailhook.environment", '')
        repo_conf.set_git_config("multimailhook.mailinglist", '')
        repo_conf.set_git_config("multimailhook.from", '')
        repo_conf.set_git_config("multimailhook.emailPrefix", '')
      end

      @gitolite_config.add_repo(repo_conf)

      repo_conf.permissions = build_permissions(repository)
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
          @gitolite_config.rm_repo(old_repo_name)
          handle_repository_add(repository, true)
        else
          return false
        end
      end

    end


    def build_permissions(repository)
      users   = repository.project.member_principals.map(&:user).compact.uniq
      project = repository.project

      rewind = []
      write  = []
      read   = []

      if project.active?
        rewind_users = users.select{|user| user.allowed_to?(:manage_repository, project)}
        write_users  = users.select{|user| user.allowed_to?(:commit_access, project) && !user.allowed_to?(:manage_repository, project)}
        read_users   = users.select{|user| user.allowed_to?(:view_changesets, project) && !user.allowed_to?(:commit_access, project) && !user.allowed_to?(:manage_repository, project)}

        ## REWIND
        rewind_users.each do |user|
          rewind += get_keys(user) if user.gitolite_public_keys.active.user_key.all.any?
        end

        ## WRITE
        write_users.each do |user|
          write  += get_keys(user) if user.gitolite_public_keys.active.user_key.all.any?
        end

        ## READ
        read_users.each do |user|
          read += get_keys(user) if user.gitolite_public_keys.active.user_key.all.any?
        end

        ## DEPLOY KEY
        if repository.repository_deployment_credentials.active.any?
          repository.repository_deployment_credentials.active.each do |cred|
            if cred.perm == "RW+"
              rewind << cred.gitolite_public_key.owner
            elsif cred.perm == "R"
              read << cred.gitolite_public_key.owner
            end
          end
        end

        read << "DUMMY_REDMINE_KEY" if read.empty? && write.empty? && rewind.empty?
        read << "gitweb" if User.anonymous.allowed_to?(:browse_repository, project)
        read << "daemon" if User.anonymous.allowed_to?(:view_changesets, project) && repository.extra.git_daemon == 1
      else
        read << "ARCHIVED_REDMINE_KEY"
      end

      permissions = {}
      permissions["RW+"] = {"" => rewind.uniq.sort} unless rewind.empty?
      permissions["RW"] = {"" => write.uniq.sort} unless write.empty?
      permissions["R"] = {"" => read.uniq.sort} unless read.empty?

      [permissions]
    end


    def get_keys(user)
      array = []
      user.gitolite_public_keys.active.user_key.all.each do |key|
        array.push(key.owner)
      end
      return array
    end


    def clean_path(path_list)
      path_list.uniq.sort.reverse.each do |path|
        begin
          logger.info { "#{@action} : cleaning repository path : '#{path}'" }
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rmdir '#{path}' 2>/dev/null || true")
        rescue RedmineGitolite::GitHostingException => e
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
      rescue Exception => e
        empty_repo = false
      end

      return empty_repo
    end


    def move_physical_repo(old_path, new_path, new_parent_path)
      ## CASE 1
      if old_path == new_path
        logger.info { "#{@action} : old repository and new repository are identical '#{old_path}', nothing to do, exit !" }
        return true
      end

      ## CASE 2
      if !RedmineGitolite::GitHosting.file_exists? old_path
        logger.error { "#{@action} : old repository '#{old_path}' does not exist, cannot move it, exit !" }
        return false
      end

      ## CASE 3
      if RedmineGitolite::GitHosting.file_exists? new_path
        if is_repository_empty?(new_path)
          logger.warn { "#{@action} : target repository '#{new_path}' already exists and is empty, remove it ..." }
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{new_path}'")
          rescue RedmineGitolite::GitHostingException => e
            logger.error { "#{@action} : removing existing target repository failed, exit !" }
            return false
          end
        else
          logger.warn { "#{@action} : target repository '#{new_path}' exists and is not empty, considered as already moved, remove the old_path" }
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{old_path}'")
            return true
          rescue RedmineGitolite::GitHostingException => e
            logger.error { "#{@action} : removing source repository directory failed, exit !" }
            return false
          end
        end
      end

      logger.debug { "#{@action} : moving Gitolite repository from '#{old_path}' to '#{new_path}'" }

      if !RedmineGitolite::GitHosting.file_exists? new_parent_path
        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mkdir -p '#{new_parent_path}'")
        rescue RedmineGitolite::GitHostingException => e
          logger.error { "#{@action} : creation of parent path '#{new_parent_path}' failed, exit !" }
          return false
        end
      end

      begin
        RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mv '#{old_path}' '#{new_path}'")
        logger.info { "#{@action} : done !" }
        return true
      rescue RedmineGitolite::GitHostingException => e
        logger.error { "move_physical_repo(#{old_path}, #{new_path}) failed" }
        return false
      end

    end

  end
end
