# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteWrappers
    module Repositories
      class DeleteRepository < GitoliteWrappers::Base
        def call
          if repository.present?
            delete_repository
          else
            log_object_dont_exist
          end
        end

        def repository
          @repository ||= object_id.symbolize_keys
        end

        def delete_repository
          admin.transaction do
            delete_gitolite_repository repository
            gitolite_admin_repo_commit repository[:repo_name]
          end

          # Call Gitolite plugins
          logger.info 'Execute Gitolite Plugins'

          # Move repository to RecycleBin
          RedmineGitHosting::Plugins.execute :post_delete, repository
        end
      end
    end
  end
end
