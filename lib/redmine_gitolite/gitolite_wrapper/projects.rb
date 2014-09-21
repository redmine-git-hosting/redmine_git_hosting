module RedmineGitolite

  module GitoliteWrapper

    class Projects < Admin

      include RedmineGitolite::GitoliteWrapper::ProjectsHelper
      include RedmineGitolite::GitoliteWrapper::RepositoriesHelper


      def update_projects
        if object_id == 'all'
          projects = Project.includes(:repositories).all
        elsif object_id == 'active'
          projects = Project.active.includes(:repositories).all
        elsif object_id == 'active_or_closed'
          projects = Project.active_or_closed.includes(:repositories).all
        else
          projects = object_id.map{ |project_id| Project.find_by_id(project_id) }
        end

        perform_update(projects)
      end


      def move_repositories
        projects = Project.find_by_id(object_id).self_and_descendants

        # Only take projects that have Git repos.
        git_projects = projects.uniq.select{ |p| p.gitolite_repos.any? }
        return if git_projects.empty?

        admin.transaction do
          @delete_parent_path = []
          handle_repositories_move(git_projects)
          clean_path(@delete_parent_path)
        end
      end


      def move_repositories_tree
        projects = Project.includes(:repositories).all.select{ |x| x.parent_id.nil? }

        admin.transaction do
          @delete_parent_path = []

          projects.each do |project|
            git_projects = project.self_and_descendants.uniq.select{ |p| p.gitolite_repos.any? }

            next if git_projects.empty?

            handle_repositories_move(git_projects)
          end

          clean_path(@delete_parent_path)
        end
      end


      private


      def perform_update(projects)
        git_projects = projects.uniq.select{ |p| p.gitolite_repos.any? }
        return if git_projects.empty?

        admin.transaction do
          git_projects.each do |project|
            handle_project_update(project)
            gitolite_admin_repo_commit("#{project.identifier}")
          end
        end
      end


      def handle_project_update(project)
        project.gitolite_repos.each do |repository|
          if options[:force] == true
            handle_repository_add(repository, :force => true)
          else
            handle_repository_update(repository)
          end
        end
      end

    end
  end
end
