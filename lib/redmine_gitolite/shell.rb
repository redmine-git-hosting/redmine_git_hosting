module RedmineGitolite

  class Shell

    def logger
      RedmineGitolite::Log.get_logger(:worker)
    end

    REPOSITORIES_METHODS = [
      :add_repository,
      :update_repository,
      :delete_repositories,
      :update_repository_default_branch,
      :create_readme_file
    ]

    USERS_METHODS = [
      :add_ssh_key,
      :update_ssh_keys,
      :delete_ssh_key,
      :update_all_ssh_keys_forced
    ]

    PROJECTS_METHODS = [
      :update_project,
      :update_projects,
      :update_all_projects,
      :update_all_projects_forced,
      :update_members,
      :update_role,
      :move_repositories,
      :move_repositories_tree
    ]

    ADMIN_METHODS = [
      :purge_recycle_bin
    ]


    def initialize(action, object_id, options)
      @action = action.to_sym
      @object_id = object_id
      @options = options.symbolize_keys
    end


    def handle_command
      if @action.nil?
        logger.error { "action is nil, exit !" }
        return false
      end

      if @object_id.nil?
        logger.error { "#{@action} : object_id is nil, exit !" }
        return false
      end

      if REPOSITORIES_METHODS.include?(@action)
        gitolite_admin = RedmineGitolite::AdminRepositories.new(@object_id, @action, @options)
        gitolite_admin.send(@action)
      elsif PROJECTS_METHODS.include?(@action)
        gitolite_admin = RedmineGitolite::AdminProjects.new(@object_id, @action, @options)
        gitolite_admin.send(@action)
      elsif USERS_METHODS.include?(@action)
        gitolite_admin = RedmineGitolite::AdminUsers.new(@object_id, @action, @options)
        gitolite_admin.send(@action)
      elsif ADMIN_METHODS.include?(@action)
        gitolite_admin = RedmineGitolite::Admin.new(@object_id, @action, @options)
        gitolite_admin.send(@action)
      end
    end

  end
end
