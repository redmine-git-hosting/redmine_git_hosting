module RedmineGitHosting
  module GitoliteHandlers
    module Repositories
      class DeleteRepository < Base

        def call
          if configuration_exists?
            log_ok_and_continue('delete it ...')

            # Delete Gitolite repository
            delete_repository_config
          else
            log_repo_not_exist('exit !')
          end
        end


        def gitolite_repo_name
          repository[:repo_name]
        end


        def gitolite_repo_path
          repository[:repo_path]
        end

      end
    end
  end
end
