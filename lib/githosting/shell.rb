module Githosting

  class Shell

    @@logger = nil
    def logger
      @@logger ||= GitoliteLogger.get_logger(:worker)
    end


    def handle_command(action, object_id)

      if object_id.nil?
        logger.error "#{action} : object_id is nil, exit !"
        return false
      end

      object = nil
      method = nil

      case action.to_sym

        when :add_repository then
          object = Repository.find_by_id(object_id)
          method = :add_repository

        when :update_repository then
          object = Repository.find_by_id(object_id)
          method = :update_repository

        when :delete_repositories then
          if !object_id.empty?
            object = object_id
            method = :delete_repositories
          end

        when :move_repositories then
          object = Project.find_by_id(object_id)
          method = :move_repositories

        when :move_repositories_tree then
          object = Project.active_or_archived.find(:all, :include => :repositories).select { |x| x.parent_id.nil? }
          method = :move_repositories_tree

        when :add_ssh_key then
          object = User.find_by_id(object_id)
          method = :update_user

        when :update_ssh_keys then
          object = User.find_by_id(object_id)
          method = :update_user

        when :delete_ssh_key then
          if !object_id.empty?
            object = object_id
            method = :delete_ssh_key
          end

        when :update_project then
          object = Project.find_by_id(object_id)
          method = :update_projects

        when :update_projects then
          if !object_id.empty?
            object = Array.new
            object_id.each do |project_id|
              project = Project.find_by_id(project_id)
              if !project.nil?
                object.push(project)
              end
            end
            method = :update_projects
          end

        when :update_all_projects then
          projects = Project.active_or_archived.find(:all, :include => :repositories)
          if projects.length > 0
            object = projects
            method = :update_projects
          end

        when :update_all_projects_forced then
          projects = Project.active_or_archived.find(:all, :include => :repositories)
          if projects.length > 0
            object = projects
            method = :update_projects_forced
          end

        when :update_members then
          object = Project.find_by_id(object_id)
          method = :update_projects

        when :update_role then
          role = Role.find_by_id(object_id)
          if !role.nil?
            projects = role.members.map(&:project).flatten.uniq.compact
            if projects.length > 0
              object = projects
              method = :update_projects
            end
          end
      end

      if !object.nil?
        if !method.nil?
          gr = GitoliteRedmine::AdminHandler.new
          gr.send(method, object, action)
        else
          logger.error "method is nil"
        end
      else
        logger.error "object is nil"
      end
    end

  end
end
