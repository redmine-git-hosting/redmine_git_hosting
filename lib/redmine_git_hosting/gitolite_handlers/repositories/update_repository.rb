module RedmineGitHosting
  module GitoliteHandlers
    module Repositories
      class UpdateRepository < Base

        def call
          if configuration_exists?
            log_ok_and_continue('update it ...')

            # Update Gitolite repository
            update_repository_config
          else
            log_repo_not_exist('exit !')
          end
        end


        def gitolite_repo_name
          repository.gitolite_repository_name
        end


        def gitolite_repo_path
          repository.gitolite_repository_path
        end

      end
    end
  end
end
