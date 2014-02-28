module RedmineGitolite

  class Shell


    def logger
      RedmineGitolite::Log.get_logger(:worker)
    end


    def initialize(action, object_id)
      @action = action
      @object_id = object_id
    end


    def handle_command
      if @action.nil?
        logger.error "action is nil, exit !"
        return false
      end

      if @object_id.nil?
        logger.error "#{@action} : object_id is nil, exit !"
        return false
      end

      method, object = self.send(@action)

      if !object.nil?
        if !object.is_a?(Array)
          call_gitolite(method, object)
        elsif !object.empty?
          call_gitolite(method, object)
        else
          return false
        end
      else
        logger.error "object is nil"
        return false
      end
    end


    private


    def call_gitolite(method, object)
      gr = RedmineGitolite::Admin.new
      gr.send(method, object, @action)
    end


    def add_repository
      method = :add_repository
      object = Repository.find_by_id(@object_id)
      return method, object
    end


    def update_repository
      method = :update_repository
      object = Repository.find_by_id(@object_id)
      return method, object
    end


    def delete_repositories
      method = :delete_repositories
      object = @object_id
      return method, object
    end


    def move_repositories
      method = :move_repositories
      object = Project.find_by_id(@object_id)
      return method, object
    end


    def move_repositories_tree
      method = :move_repositories_tree
      object = Project.active_or_archived.find(:all, :include => :repositories).select { |x| x.parent_id.nil? }
      return method, object
    end


    def add_ssh_key
      method = :update_user
      object = User.find_by_id(@object_id)
      return method, object
    end


    def update_ssh_keys
      method = :update_user
      object = User.find_by_id(@object_id)
      return method, object
    end


    def delete_ssh_key
      method = :delete_ssh_key
      object = @object_id
      return method, object
    end


    def update_project
      method = :update_projects
      object = Project.find_by_id(@object_id)
      return method, object
    end


    def update_projects
      method = :update_projects

      object = []
      @object_id.each do |project_id|
        project = Project.find_by_id(project_id)
        if !project.nil?
          object.push(project)
        end
      end

      return method, object
    end


    def update_all_projects
      method = :update_projects

      object = []
      projects = Project.active_or_archived.find(:all, :include => :repositories)
      if projects.length > 0
        object = projects
      end

      return method, object
    end


    def update_all_projects_forced
      method = :update_projects_forced

      object = []
      projects = Project.active_or_archived.find(:all, :include => :repositories)
      if projects.length > 0
        object = projects
      end

      return method, object
    end


    def update_all_ssh_keys_forced
      method = :update_ssh_keys_forced
      object = User.all

      return method, object
    end


    def update_members
      method = :update_projects
      object = Project.find_by_id(@object_id)

      return method, object
    end


    def update_role
      method = :update_projects

      object = []
      role = Role.find_by_id(@object_id)
      if !role.nil?
        projects = role.members.map(&:project).flatten.uniq.compact
        if projects.length > 0
          object = projects
        end
      end

      return method, object
    end


    def purge_recycle_bin
      method = :purge_recycle_bin
      object = @object_id

      return method, object
    end

  end
end
