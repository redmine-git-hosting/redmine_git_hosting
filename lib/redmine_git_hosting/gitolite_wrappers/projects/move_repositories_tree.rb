module RedmineGitHosting
  module GitoliteWrappers
    module Projects
      class MoveRepositoriesTree < GitoliteWrappers::Base

        include Common

        # Move repositories tree in a single transaction
        #
        def call
          admin.transaction do
            @delete_parent_path = []
            projects.each do |project|
              # Only take projects that have Git repos.
              git_projects = project.self_and_descendants.uniq.select { |p| p.gitolite_repos.any? }
              next if git_projects.empty?
              @delete_parent_path += handle_repositories_move(git_projects)
            end
            # Remove empty directories
            clean_path(@delete_parent_path)
          end
        end


        def projects
          @projects ||= Project.includes(:repositories).all.select { |x| x.parent_id.nil? }
        end

      end
    end
  end
end
