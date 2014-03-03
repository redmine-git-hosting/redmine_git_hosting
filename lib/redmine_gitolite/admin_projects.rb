module RedmineGitolite

  class AdminProjects < Admin

    include RedmineGitolite::AdminRepositoriesHelper


    def update_project
      object = Project.find_by_id(@object_id)
      do_update_projects(object)
    end


    def update_projects
      object = []

      @object_id.each do |project_id|
        project = Project.find_by_id(project_id)
        if !project.nil?
          object.push(project)
        end
      end

      do_update_projects(object)
    end


    def update_all_projects
      object = []
      projects = Project.active_or_archived.find(:all, :include => :repositories)
      if projects.length > 0
        object = projects
      end

      do_update_projects(object)
    end


    def update_all_projects_forced
      object = []
      projects = Project.active_or_archived.find(:all, :include => :repositories)
      if projects.length > 0
        object = projects
      end

      do_update_projects(object)
    end


    def update_members
      object = Project.find_by_id(@object_id)
      do_update_projects(object)
    end


    def update_role
      object = []
      role = Role.find_by_id(@object_id)
      if !role.nil?
        projects = role.members.map(&:project).flatten.uniq.compact
        if projects.length > 0
          object = projects
        end
      end

      do_update_projects(object)
    end


    def move_repositories
      project = Project.find_by_id(@object_id)

      wrapped_transaction do
        @delete_parent_path = []
        handle_repositories_move(project)
        clean_path(@delete_parent_path)
      end
    end


    def move_repositories_tree
      projects = Project.active_or_archived.find(:all, :include => :repositories).select { |x| x.parent_id.nil? }

      wrapped_transaction do
        @delete_parent_path = []

        projects.each do |project|
          handle_repositories_move(project)
        end

        clean_path(@delete_parent_path)
      end
    end


    private


    def do_update_projects(projects)
      projects = (projects.is_a?(Array) ? projects : [projects])

      if projects.detect{|p| p.repositories.detect{|r| r.is_a?(Repository::Git)}}
        wrapped_transaction do
          projects.each do |project|
            handle_project_update(project)
            gitolite_admin_repo_commit("#{project.identifier}")
          end
        end
      end
    end


    def update_projects_forced(projects)
      projects = (projects.is_a?(Array) ? projects : [projects])

      if projects.detect{|p| p.repositories.detect{|r| r.is_a?(Repository::Git)}}
        wrapped_transaction do
          projects.each do |project|
            handle_project_update(project, true)
            gitolite_admin_repo_commit("#{project.identifier}")
          end
        end
      end
    end


    def handle_project_update(project, force = false)
      project.gitolite_repos.each do |repository|
        if force == true
          handle_repository_add(repository, true)
        else
          handle_repository_update(repository)
        end
      end
    end

  end
end
