require 'gitolite'
require 'lockfile'

module RedmineGitolite

  class Admin

    def initialize
      @gitolite_admin_dir = RedmineGitolite::Config.gitolite_admin_dir
      @gitolite_config_file = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_config_file)
      @gitolite_config_file_path = File.join(@gitolite_admin_dir, 'conf', @gitolite_config_file)
      @delete_git_repositories = RedmineGitolite::ConfigRedmine.get_setting(:delete_git_repositories, true)
      @gitolite_server_port = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_server_port)
      @gitolite_admin_url = RedmineGitolite::Config.gitolite_admin_url
      @gitolite_admin_ssh_script_path = RedmineGitolite::Config.gitolite_admin_ssh_script_path
      @lock_file_path = File.join(RedmineGitolite::Config.get_temp_dir_path, 'redmine_git_hosting_lock')
    end


    def add_repository(repository, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        handle_repository_add(repository, 'add_repository')

        gitolite_admin_repo_commit("#{action} : #{repository.gitolite_repository_name}")

        recycle = RedmineGitolite::Recycle.new

        if !recycle.recover_repository_if_present?(repository)
          logger.info "Let Gitolite create empty repository : '#{repository.gitolite_repository_path}'"
        else
          logger.info "Restored existing Gitolite repository : '#{repository.gitolite_repository_path}' for update"
        end

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def update_repository(repository, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        handle_repository_update(repository, action)

        gitolite_admin_repo_commit("#{action} : #{repository.gitolite_repository_name}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def delete_repositories(repositories_array, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        repositories_array.each do |repository_data|
          handle_repository_delete(repository_data)

          recycle = RedmineGitolite::Recycle.new
          recycle.move_repository_to_recycle(repository_data) if @delete_git_repositories

          gitolite_admin_repo_commit("#{action} : #{repository_data['repo_name']}")
        end

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def move_repositories(project, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        @delete_parent_path = []

        handle_repositories_move(project, action)

        clean_path(@delete_parent_path)

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def move_repositories_tree(projects, action)
      get_lock(action) do
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
        get_lock(action) do
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
        get_lock(action) do
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


    def update_ssh_keys_forced(users, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        users.each do |user|
          handle_user_update(user)
          gitolite_admin_repo_commit("#{action} : #{user.login}")
        end

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def update_user(user, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        handle_user_update(user)

        gitolite_admin_repo_commit("#{action} : #{user.login}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def delete_ssh_key(ssh_key, action)
      get_lock(action) do
        gitolite_admin_repo_clone

        handle_ssh_key_delete(ssh_key)

        gitolite_admin_repo_commit("#{action} : #{ssh_key['title']}")

        gitolite_admin_repo_push(action)

        logger.info "#{action} : done !"
      end
    end


    def purge_recycle_bin(repositories_array, action)
      recycle = RedmineGitolite::Recycle.new
      recycle.delete_expired_files(repositories_array)
      logger.info "#{action} : done !"
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:worker)
    end


    ###############################
    ##                           ##
    ##      LOCK FUNCTIONS       ##
    ##                           ##
    ###############################


    @@lock_file = nil

    def get_lock_file
      begin
        lock_file ||= File.new(@lock_file_path, File::CREAT|File::RDONLY)
      rescue Exception => e
        lock_file = nil
      end

      @@lock_file = lock_file
    end


    def get_lock(action)
      lock_file = get_lock_file

      if !lock_file.nil? && File.exist?(lock_file)
        File.open(lock_file) do |file|
          file.sync = true
          file.flock(File::LOCK_EX)
          logger.debug "#{action} : get lock !"

          yield

          file.flock(File::LOCK_UN)
          logger.debug "#{action} : lock released !"
        end
      else
        logger.error "#{action} : cannot get lock, file does not exist #{lock_file} !"
      end
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


    def gitolite_admin_repo_clone
      if (File.exists? "#{@gitolite_admin_dir}") && (File.exists? "#{@gitolite_admin_dir}/.git") && (File.exists? "#{@gitolite_admin_dir}/keydir") && (File.exists? "#{@gitolite_admin_dir}/conf")
        @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
      else
        begin
          logger.info "Clone Gitolite Admin Repo : #{@gitolite_admin_url} (port : #{@gitolite_server_port}) to #{@gitolite_admin_dir}"

          RedmineGitolite::GitHosting.shell %[rm -rf "#{@gitolite_admin_dir}"]
          RedmineGitolite::GitHosting.shell %[env GIT_SSH=#{@gitolite_admin_ssh_script_path} git clone ssh://#{@gitolite_admin_url} #{@gitolite_admin_dir}]
          RedmineGitolite::GitHosting.shell %[chmod 700 "#{@gitolite_admin_dir}"]

          @gitolite_admin = Gitolite::GitoliteAdmin.new(@gitolite_admin_dir)
        rescue => e
          logger.error e.message
          logger.error "Cannot clone Gitolite Admin repository !!"
          return false
        end
      end

      if @gitolite_config_file != RedmineGitolite::Config::GITOLITE_DEFAULT_CONFIG_FILE
        if !File.exists?(@gitolite_config_file_path)
          begin
            RedmineGitolite::GitHosting.shell %[touch "#{@gitolite_config_file_path}"]
          rescue => e
            logger.error e.message
            logger.error "Cannot create Gitolite configuration file '#{@gitolite_config_file_path}' !!"
            return false
          end
        end
      else
        if !File.exists?(@gitolite_config_file_path)
          logger.error "Gitolite configuration file does not exist '#{@gitolite_config_file_path}' !!"
          logger.error "Please check your Gitolite installation"
          return false
        end
      end

      logger.info "Using Gitolite configuration file : '#{@gitolite_config_file_path}'"
      @gitolite_admin.config = @gitolite_config = Gitolite::Config.new(@gitolite_config_file_path)
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
          repo_list.push(repository.gitolite_repository_name)
          do_move_repositories(repository)
        end

        gitolite_admin_repo_commit("#{action} : #{project.identifier} | #{repo_list}")
      end
    end


    def handle_repository_add(repository, action, force = false)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
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
      repo_conf.set_git_config("redmineGitolite.projectId", repository.project.identifier.to_s)
      repo_conf.set_git_config("redmineGitolite.repositoryId", "#{repository.identifier || ''}")
      repo_conf.set_git_config("redmineGitolite.repositoryKey", repository.extra.key)

      # Set mail-notifications hook params
      if repository.extra.git_notify == 1
        mailing_list   = repository.mailing_list_params[:mailing_list]
        email_prefix   = repository.mailing_list_params[:email_prefix]
        sender_address = repository.mailing_list_params[:sender_address]

        if !mailing_list.empty?
          repo_conf.set_git_config("multimailhook.environment", "gitolite")
          repo_conf.set_git_config("multimailhook.mailinglist", mailing_list.keys.join(", "))
          repo_conf.set_git_config("multimailhook.from", email_prefix)
          repo_conf.set_git_config("multimailhook.emailPrefix", sender_address)

          # Set SMTP server for mail-notifications hook
          #~ repo_conf.set_git_config("multimailhook.smtpServer", ActionMailer::Base.smtp_settings[:address])
        end
      end

      @gitolite_config.add_repo(repo_conf)

      repo_conf.permissions = build_permissions(repository)
    end


    def handle_repository_update(repository, action)
      repo_name = repository.gitolite_repository_name
      repo_path = repository.gitolite_repository_path
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
      repo_conf.set_git_config("redmineGitolite.projectId", repository.project.identifier.to_s)
      repo_conf.set_git_config("redmineGitolite.repositoryId", "#{repository.identifier || ''}")
      repo_conf.set_git_config("redmineGitolite.repositoryKey", repository.extra.key)

      # Set mail-notifications hook params
      if repository.extra.git_notify == 1
        mailing_list   = repository.mailing_list_params[:mailing_list]
        email_prefix   = repository.mailing_list_params[:email_prefix]
        sender_address = repository.mailing_list_params[:sender_address]

        if !mailing_list.empty?
          repo_conf.set_git_config("multimailhook.environment", "gitolite")
          repo_conf.set_git_config("multimailhook.mailinglist", mailing_list.keys.join(", "))
          repo_conf.set_git_config("multimailhook.from", email_prefix)
          repo_conf.set_git_config("multimailhook.emailPrefix", sender_address)

          # Set SMTP server for mail-notifications hook
          #~ repo_conf.set_git_config("multimailhook.smtpServer", ActionMailer::Base.smtp_settings[:address])
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
      repo_id   = repository.redmine_name
      repo_name = repository.old_repository_name

      repo_conf = @gitolite_config.repos[repo_name]

      old_repo_name = repository.old_repository_name
      new_repo_name = repository.new_repository_name

      old_relative_path  = repository.url
      new_relative_path  = repository.gitolite_repository_path

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
        if move_physical_repo(old_relative_path, new_relative_path, new_relative_parent_path)
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


    def is_repository_empty?(new_path)
      empty_repo = false

      begin
        output = RedmineGitolite::GitHosting.execute_command(:shell_cmd, "find '#{new_path}/objects' -type f | wc -l").chomp.gsub('\n', '')
        logger.debug "move_repository : counted objects in repository directory '#{new_path}' : '#{output}'"

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
        logger.info "move_repository : old repository and new repository are identical '#{old_path}', nothing to do, exit !"
        return true
      end

      ## CASE 2
      if !RedmineGitolite::GitHosting.file_exists? old_path
        logger.error "move_repository : old repository '#{old_path}' does not exist, cannot move it, exit !"
        return false
      end

      ## CASE 3
      if RedmineGitolite::GitHosting.file_exists? new_path
        if is_repository_empty?(new_path)
          logger.warn "move_repository : target repository '#{new_path}' already exists and is empty, remove it..."
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{new_path}'")
          rescue => e
            logger.error "move_repository : removing existing target repository failed, exit !"
            return false
          end
        else
          logger.warn "move_repository : target repository '#{new_path}' exists and is not empty, considered as already moved, remove the old_path"
          begin
            RedmineGitolite::GitHosting.execute_command(:shell_cmd, "rm -rf '#{old_path}'")
            return true
          rescue => e
            logger.error "move_repository : removing source repository directory failed, exit !"
            return false
          end
        end
      end

      logger.debug "move_repository : moving Gitolite repository from '#{old_path}' to '#{new_path}'"

      if !RedmineGitolite::GitHosting.file_exists? new_parent_path
        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mkdir -p '#{new_parent_path}'")
        rescue => e
          logger.error "move_repository : creation of parent path '#{new_parent_path}' failed, exit !"
          return false
        end
      end

      begin
        RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mv '#{old_path}' '#{new_path}'")
        logger.info "move_repository : done !"
        return true
      rescue => e
        logger.error "move_physical_repo(#{old_path}, #{new_path}) failed"
        logger.error e.message
        return false
      end

    end

  end
end
