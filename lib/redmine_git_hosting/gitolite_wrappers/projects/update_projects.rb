module RedmineGitHosting
  module GitoliteWrappers
    module Projects
      class UpdateProjects < GitoliteWrappers::Base

        def call
          return if git_projects.empty?
          admin.transaction do
            git_projects.each do |project|
              if project.gitolite_repos.any?
                handle_project_update(project)
                gitolite_admin_repo_commit(project.identifier)
              end
            end
          end
        end


        def git_projects
          @git_projects ||= projects.uniq.select { |p| p.gitolite_repos.any? }
        end


        def projects
          @projects ||=
            case object_id
            when 'all'
              Project.includes(:repositories).all
            when 'active'
              Project.active.includes(:repositories).all
            when 'active_or_closed'
              Project.active_or_closed.includes(:repositories).all
            else
              object_id.map { |project_id| Project.find_by_id(project_id) }
            end
        end


        def handle_project_update(project)
          project.gitolite_repos.each do |repository|
            options[:force] == true ? create_gitolite_repository(repository) : update_gitolite_repository(repository)
          end
        end

      end
    end
  end
end
