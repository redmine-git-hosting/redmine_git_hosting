module RedmineGitHosting
  module GitoliteWrappers
    module Projects
      class MoveRepositories < GitoliteWrappers::Base

        include Common

        def call
          return if git_projects.empty?
          admin.transaction do
            @delete_parent_path = []
            @delete_parent_path += handle_repositories_move(git_projects)
            # Remove empty directories
            clean_path(@delete_parent_path)
          end
        end


        def git_projects
          @git_projects ||= projects.uniq.select { |p| p.gitolite_repos.any? }
        end


        def projects
          @projects ||= Project.find_by_id(object_id).self_and_descendants
        end

      end
    end
  end
end
