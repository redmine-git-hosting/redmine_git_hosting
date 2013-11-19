module GitoliteRedmine

  class AdminHandler

    @@logger = nil
    def logger
      @@logger ||= GitoliteLogger.get_logger(:worker)
    end


    def add_repository(repository, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        handle_repository_add(repository, 'add_repository')

        gitolite_admin_repo_commit("#{action} : #{GitHosting.repository_name(repository)}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def update_repository(repository, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        handle_repository_update(repository, action)

        gitolite_admin_repo_commit("#{action} : #{GitHosting.repository_name(repository)}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def delete_repositories(repositories_array, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        repositories_array.each do |repository_data|
          handle_repository_delete(repository_data)

          GitHosting::GitoliteRecycle.move_repository_to_recycle(repository_data) if GitHostingConf.delete_git_repositories?

          gitolite_admin_repo_commit("#{action} : #{repository_data['repo_name']}")
        end

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def move_repositories(project, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        @delete_parent_path = []

        handle_repositories_move(project, action)

        clean_path(@delete_parent_path)

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def move_repositories_tree(projects, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        @delete_parent_path = []

        projects.each do |project|
          handle_repositories_move(project, action)
        end

        clean_path(@delete_parent_path)

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def update_projects(projects, action)
      projects = (projects.is_a?(Array) ? projects : [projects])

      if projects.detect{|p| p.repositories.detect{|r| r.is_a?(Repository::Git)}}
        GitHosting.lock(action) do
          gitolite_admin_repo_clone

          projects.each do |project|
            handle_project_update(project, action)
            gitolite_admin_repo_commit("#{action} : #{project.identifier}")
          end

          gitolite_admin_repo_push(action)

          logger.info "#{action} : done !"
        end
      end
    end


    def update_projects_forced(projects, action)
      projects = (projects.is_a?(Array) ? projects : [projects])

      if projects.detect{|p| p.repositories.detect{|r| r.is_a?(Repository::Git)}}
        GitHosting.lock(action) do
          gitolite_admin_repo_clone

          projects.each do |project|
            handle_project_update(project, action, true)
            gitolite_admin_repo_commit("#{action} : #{project.identifier}")
          end

          gitolite_admin_repo_push(action)

          logger.info "#{action} : done !"
        end
      end
    end


    def update_user(user, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        handle_user_update(user)

        gitolite_admin_repo_commit("#{action} : #{user.login}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def delete_ssh_key(ssh_key, action)
      GitHosting.lock(action) do
        gitolite_admin_repo_clone

        handle_ssh_key_delete(ssh_key)

        gitolite_admin_repo_commit("#{action} : #{ssh_key['title']}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    private


    @gitolite_admin_dir = nil
    def gitolite_admin_dir
      @gitolite_admin_dir ||= File.join(GitHosting.temp_dir_path, GitHostingConf::GITOLITE_ADMIN_REPO)
    end


    def gitolite_admin_repo_commit(message = nil)
      @gitolite_admin.save(message)
    end


    def gitolite_admin_repo_push(action)
      logger.info "#{action} : pushing to Gitolite..."
      begin
        @gitolite_admin.apply
      rescue => e
        logger.error "Error : #{e.message}"
      end
    end


    @@gitolite_admin_conf = nil
    def gitolite_admin_repo_clone
      if (File.exists? "#{gitolite_admin_dir}") && (File.exists? "#{gitolite_admin_dir}/.git") && (File.exists? "#{gitolite_admin_dir}/keydir") && (File.exists? "#{gitolite_admin_dir}/conf")
        @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
      else
        begin
          logger.info "Clone Gitolite Admin Repo : #{GitHostingConf.gitolite_admin_url} (port : #{GitHostingConf.gitolite_server_port}) to #{@gitolite_admin_dir}"

          GitHosting.shell %[rm -rf "#{@gitolite_admin_dir}"]
          GitHosting.shell %[env GIT_SSH=#{GitHosting.gitolite_admin_ssh_runner} git clone ssh://#{GitHostingConf.gitolite_admin_url} #{@gitolite_admin_dir}]
          GitHosting.shell %[chmod 700 "#{@gitolite_admin_dir}"]

          @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
        rescue => e
          logger.error e.message
          logger.error "Cannot clone Gitolite Admin repository !!"
          return false
        end
      end

      if GitHostingConf.gitolite_config_file != GitHostingConf::GITOLITE_CONFIG_FILE
        config_file = "#{@gitolite_admin_dir}/conf/#{GitHostingConf.gitolite_config_file}"
        if !File.exists?(config_file)
          begin
            GitHosting.shell %[touch "#{config_file}"]
          rescue => e
            logger.error e.message
            logger.error "Cannot create Gitolite configuration file '#{config_file}' !!"
            return false
          end
        end
      else
        config_file = "#{@gitolite_admin_dir}/conf/#{GitHostingConf::GITOLITE_CONFIG_FILE}"
        if !File.exists?(config_file)
          logger.error "Gitolite configuration file does not exist '#{config_file}' !!"
          logger.error "Please check your Gitolite installation"
          return false
        end
      end

      logger.info "Using Gitolite configuration file : '#{config_file}'"
      @gitolite_admin.config = @gitolite_config = Gitolite::Config.new(config_file)
    end


    def handle_project_update(project, action, force = false)
      project.gitolite_repos.each do |repository|
        if force == true
          handle_repository_add(repository, action, true)
        else
          handle_repository_update(repository, action)
        end
      end
    end


    def handle_repositories_move(project, action)
      projects = project.self_and_descendants

      # Only take projects that have Git repos.
      git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}
      return if git_projects.empty?

      git_projects.reverse.each do |project|
        repo_list = []

        project.gitolite_repos.reverse.each do |repository|
          repo_list.push(GitHosting.repository_name(repository))
          do_move_repositories(repository)
        end

        gitolite_admin_repo_commit("#{action} : #{project.identifier} | #{repo_list}")
      end
    end


    def handle_repository_add(repository, action, force = false)
      repo_name = GitHosting.repository_name(repository)
      repo_path = GitHosting.repository_path(repository)
      repo_conf = @gitolite_config.repos[repo_name]

      if !repo_conf
        logger.info "#{action} : repository '#{repo_name}' does not exist in Gitolite, create it..."
        logger.debug "#{action} : repository path '#{repo_path}'"
      else
        if force == true
          logger.warn "#{action} : repository '#{repo_name}' already exists in Gitolite, force mode !"
          logger.debug "#{action} : repository path '#{repo_path}'"
          @gitolite_config.rm_repo(repo_name)
        else
          logger.warn "#{action} : repository '#{repo_name}' already exists in Gitolite, exit !"
          logger.debug "#{action} : repository path '#{repo_path}'"
          return false
        end
      end

      # Create new repo object
      repo_conf = Gitolite::Config::Repo.new(repo_name)

      # Set post-receive hook params
      repo_conf.set_git_config("hooks.redmine_gitolite.projectid", repository.project.identifier.to_s)
      repo_conf.set_git_config("hooks.redmine_gitolite.repositoryid", "#{repository.identifier || ''}")
      repo_conf.set_git_config("hooks.redmine_gitolite.key", repository.extra.key)

      # Set SMTP server for mail-notifications hook
      #~ repo_conf.set_git_config("hooks.redmine_gitolite.smtpserver", ActionMailer::Base.smtp_settings[:address])

      # Set mail-notifications hook params
      if repository.extra.git_notify == 1
        mailing_list = GitHostingHelper.mailing_list_effective(repository)
        if !mailing_list.empty?
          repo_conf.set_git_config("hooks.mailinglist", mailing_list.keys.join(", "))
          repo_conf.set_git_config("hooks.senderemail", GitHostingConf.gitolite_notify_global_sender_address)
          repo_conf.set_git_config("hooks.emailprefix", GitHostingConf.gitolite_notify_global_prefix)
        end
      end

      @gitolite_config.add_repo(repo_conf)

      repo_conf.permissions = build_permissions(repository)
    end


    def handle_repository_update(repository, action)
      repo_name = GitHosting.repository_name(repository)
      repo_path = GitHosting.repository_path(repository)
      repo_conf = @gitolite_config.repos[repo_name]

      if repo_conf
        logger.info "#{action} : repository '#{repo_name}' exists in Gitolite, update it..."
        logger.debug "#{action} : repository path '#{repo_path}'"
        @gitolite_config.rm_repo(repo_name)
      else
        logger.warn "#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !"
        logger.debug "#{action} : repository path '#{repo_path}'"
        return false
      end

      # Create new repo object
      repo_conf = Gitolite::Config::Repo.new(repo_name)

      # Set post-receive hook params
      repo_conf.set_git_config("hooks.redmine_gitolite.projectid", repository.project.identifier.to_s)
      repo_conf.set_git_config("hooks.redmine_gitolite.repositoryid", "#{repository.identifier || ''}")
      repo_conf.set_git_config("hooks.redmine_gitolite.key", repository.extra.key)

      # Set SMTP server for mail-notifications hook
      #~ repo_conf.set_git_config("hooks.redmine_gitolite.smtpserver", ActionMailer::Base.smtp_settings[:address])

      # Set mail-notifications hook params
      if repository.extra.git_notify == 1
        mailing_list = GitHostingHelper.mailing_list_effective(repository)
        if !mailing_list.empty?
          repo_conf.set_git_config("hooks.mailinglist", mailing_list.keys.join(", "))
          repo_conf.set_git_config("hooks.senderemail", GitHostingConf.gitolite_notify_global_sender_address)
          repo_conf.set_git_config("hooks.emailprefix", GitHostingConf.gitolite_notify_global_prefix)
        end
      end

      @gitolite_config.add_repo(repo_conf)

      repo_conf.permissions = build_permissions(repository)
    end


    def handle_repository_delete(repository_data)
      repo_name = repository_data['repo_name']
      repo_path = repository_data['repo_path']
      repo_conf = @gitolite_config.repos[repo_name]

      if !repo_conf
        logger.warn "delete_repository : repository '#{repo_name}' does not exist in Gitolite, exit !"
        logger.debug "delete_repository : repository path '#{repo_path}'"
        return false
      else
        logger.info "delete_repository : repository '#{repo_name}' exists in Gitolite, delete it..."
        logger.debug "delete_repository : repository path '#{repo_path}'"
        @gitolite_config.rm_repo(repo_name)
      end
    end


    def handle_ssh_key_delete(ssh_key)
      remove_inactive_key(ssh_key)
    end


    def handle_user_update(user)
      add_active_keys(user.gitolite_public_keys.active)
      remove_inactive_keys(user.gitolite_public_keys.inactive)
    end


    def clean_path(path_list)
      path_list.uniq.sort.reverse.each do |path|
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} rmdir '#{path}' 2>/dev/null || true]
      end
    end


    def do_move_repositories(repository)
      repo_id   = repository.git_name
      repo_name = "#{GitHosting.old_repository_name(repository)}"
      repo_conf = @gitolite_config.repos[repo_name]

      old_repo_name = "#{GitHosting.old_repository_name(repository)}"
      new_repo_name = "#{GitHosting.new_repository_name(repository)}"

      old_relative_path  = "#{repository.url}"
      new_relative_path  = "#{GitHosting.repository_path(repository)}"

      old_relative_parent_path = old_relative_path.gsub(repo_id + '.git', '')
      new_relative_parent_path = new_relative_path.gsub(repo_id + '.git', '')

      logger.info "move_repository : Moving '#{repo_name}'..."
      logger.debug "  Old repository name (for Gitolite)           : #{old_repo_name}"
      logger.debug "  New repository name (for Gitolite)           : #{new_repo_name}"
      logger.debug "-----"
      logger.debug "  Old relative path (for Redmine code browser) : #{old_relative_path}"
      logger.debug "  New relative path (for Redmine code browser) : #{new_relative_path}"
      logger.debug "-----"
      logger.debug "  Old relative parent path (for Gitolite)      : #{old_relative_parent_path}"
      logger.debug "  New relative parent path (for Gitolite)      : #{new_relative_parent_path}"

      if !repo_conf
        logger.error "move_repositories : repository '#{repo_name}' does not exist in Gitolite, exit !"
        return false
      else
        if GitHosting.move_physical_repo(old_relative_path, new_relative_path, new_relative_parent_path)
          @delete_parent_path.push(old_relative_parent_path)

          repository.update_column(:url, new_relative_path)
          repository.update_column(:root_url, new_relative_path)

          # update gitolite conf
          @gitolite_config.rm_repo(old_repo_name)
          handle_repository_add(repository, 'move_repository', true)
        else
          return false
        end
      end
    end


    def add_active_keys(keys)
      keys.each do |key|
        parts = key.key.split
        repo_keys = @gitolite_admin.ssh_keys[key.owner]
        repo_key = repo_keys.find_all{|k| k.location == key.location && k.owner == key.owner}.first
        if repo_key
          logger.info "add_active_keys : SSH key '#{key.owner}' already exists in Gitolite, update it..."
          repo_key.type, repo_key.blob, repo_key.email = parts
          repo_key.owner = key.owner
          repo_key.location = key.location
        else
          logger.info "add_active_keys: SSH key '#{key.owner}' does not exist in Gitolite, create it..."
          repo_key = Gitolite::SSHKey.new(parts[0], parts[1], parts[2])
          repo_key.location = key.location
          repo_key.owner = key.owner
          @gitolite_admin.add_key repo_key
        end
      end
    end


    def remove_inactive_keys(keys)
      keys.each do |key|
        ssh_key = Hash.new
        ssh_key['owner']    = key.owner
        ssh_key['location'] = key.location
        logger.info "remove_inactive_key : removing inactive SSH key of '#{key.owner}'"
        remove_inactive_key(ssh_key)
      end
    end


    def remove_inactive_key(key)
      repo_keys = @gitolite_admin.ssh_keys[key['owner']]
      repo_key = repo_keys.find_all{|k| k.location == key['location'] && k.owner == key['owner']}.first
      if repo_key
        logger.info "remove_inactive_key : SSH key '#{key['owner']}' exists in Gitolite, delete it..."
        @gitolite_admin.rm_key repo_key
      else
        logger.info "remove_inactive_key : SSH key '#{key['owner']}' does not exits in Gitolite, exit !"
        return false
      end
    end


    def get_keys(user)
      array = []
      user.gitolite_public_keys.active.user_key.all.each do |key|
        array.push(key.owner)
      end
      return array
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

  end
end
