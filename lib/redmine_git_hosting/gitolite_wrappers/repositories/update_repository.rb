# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteWrappers
    module Repositories
      class UpdateRepository < GitoliteWrappers::Base
        def call
          if repository.nil?
            log_object_dont_exist
          else
            update_repository
          end
        end

        def repository
          @repository ||= Repository.find_by id: object_id
        end

        def update_repository
          admin.transaction do
            update_gitolite_repository repository
            gitolite_admin_repo_commit repository.gitolite_repository_name
          end

          # Call Gitolite plugins
          logger.info 'Execute Gitolite Plugins'

          # Delete Git Config Keys
          RedmineGitHosting::Plugins.execute :post_update, repository, **options

          # Fetch changeset
          repository.fetch_changesets
        end
      end
    end
  end
end
