module RedmineGitHosting
  module GitoliteWrappers
    module Repositories
      class MoveRepository < GitoliteWrappers::Base

        def call
          if !repository.nil?
            move_repository
          else
            log_object_dont_exist
          end
        end


        def repository
          @repository ||= Repository.find_by_id(object_id)
        end


        def move_repository
          admin.transaction do
            move_gitolite_repository(repository)
            gitolite_admin_repo_commit(repository.gitolite_repository_name)
          end

          # Fetch changeset
          repository.fetch_changesets
        end

      end
    end
  end
end
