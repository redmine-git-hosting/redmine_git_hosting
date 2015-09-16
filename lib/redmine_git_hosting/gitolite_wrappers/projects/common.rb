module RedmineGitHosting
  module GitoliteWrappers
    module Projects
      module Common

        def handle_repositories_move(projects)
          repo_list = []
          delete_parent_path = []
          projects.reverse.each do |project|
            project.gitolite_repos.reverse.each do |repository|
              repo_list << repository.gitolite_repository_name
              delete_parent_path << move_gitolite_repository(repository)
            end
            gitolite_admin_repo_commit("#{context} : #{project.identifier} | #{repo_list}")
          end
          delete_parent_path
        end


        def clean_path(path_list)
          path_list.compact.uniq.sort.reverse.each do |path|
            rmdir(path)
          end
        end


        def rmdir(path)
          logger.info("#{context} : cleaning repository path : '#{path}'")
          begin
            RedmineGitHosting::Commands.sudo_rmdir(path)
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("#{context} : error while cleaning repository path '#{path}'")
          end
        end

      end
    end
  end
end
