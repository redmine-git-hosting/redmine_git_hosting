# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteWrappers
    module Repositories
      class MoveRepository < GitoliteWrappers::Base
        def call
          if repository.nil?
            log_object_dont_exist
          else
            move_repository
          end
        end

        def repository
          @repository ||= Repository.find_by id: rails_object_id
        end

        def move_repository
          admin.transaction do
            move_gitolite_repository repository
            gitolite_admin_repo_commit repository.gitolite_repository_name
          end

          # Fetch changeset
          repository.fetch_changesets
        end
      end
    end
  end
end
