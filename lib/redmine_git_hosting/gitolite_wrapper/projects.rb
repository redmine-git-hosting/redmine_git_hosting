module RedmineGitHosting
  module GitoliteWrapper
    class Projects < Admin


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
          @delete_parent_path += handle_repositories_move(git_projects)
          # Remove empty directories
          clean_path(@delete_parent_path)
        end
      end


      def move_repositories_tree
        projects = Project.includes(:repositories).all.select{ |x| x.parent_id.nil? }
        # Move repositories tree in a single transaction
        admin.transaction do
          @delete_parent_path = []
          projects.each do |project|
            # Only take projects that have Git repos.
            git_projects = project.self_and_descendants.uniq.select{ |p| p.gitolite_repos.any? }
            next if git_projects.empty?
            @delete_parent_path += handle_repositories_move(git_projects)
          end
          # Remove empty directories
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
              RedmineGitHosting::GitoliteHandlers::RepositoryAdder.new(repository, gitolite_config, action, force: true).call
            else
              RedmineGitHosting::GitoliteHandlers::RepositoryUpdater.new(repository, gitolite_config, action).call
            end
          end
        end


        def handle_repositories_move(git_projects)
          repo_list = []
          delete_parent_path = []
          git_projects.reverse.each do |project|
            project.gitolite_repos.reverse.each do |repository|
              repo_list.push << repository.gitolite_repository_name
              delete_parent_path << RedmineGitHosting::GitoliteHandlers::RepositoryMover.new(repository, gitolite_config, action).call
            end
            gitolite_admin_repo_commit("#{action} : #{project.identifier} | #{repo_list}")
          end
          delete_parent_path
        end


        def clean_path(path_list)
          path_list.compact.uniq.sort.reverse.each do |path|
            begin
              logger.info("#{action} : cleaning repository path : '#{path}'")
              RedmineGitHosting::GitoliteWrapper.sudo_rmdir(path)
            rescue RedmineGitHosting::Error::GitoliteCommandException => e
              logger.error("#{action} : error while cleaning repository path '#{path}'")
            end
          end
        end

    end
  end
end
