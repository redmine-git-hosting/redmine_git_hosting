# frozen_string_literal: true

module RedmineGitHosting
  module GitoliteWrappers
    module Repositories
      class AddRepository < GitoliteWrappers::Base
        def call
          if repository.nil?
            log_object_dont_exist
          else
            create_repository
          end
        end

        def repository
          @repository ||= Repository.find_by id: object_id
        end

        def create_repository
          admin.transaction do
            create_gitolite_repository repository
            gitolite_admin_repo_commit repository.gitolite_repository_name

            @recovered = RedmineGitHosting::RecycleBin.restore_object_from_recycle repository.gitolite_repository_name,
                                                                                   repository.gitolite_full_repository_path

            if @recovered
              logger.info "#{context} : restored existing Gitolite repository '#{repository.gitolite_repository_path}' for update"
            else
              logger.info "#{context} : let Gitolite create empty repository '#{repository.gitolite_repository_path}'"
            end
          end

          # Call Gitolite plugins
          logger.info 'Execute Gitolite Plugins'

          # Create README file or initialize GitAnnex
          RedmineGitHosting::Plugins.execute :post_create, repository, **options.merge(recovered: @recovered)

          # Fetch changeset
          repository.fetch_changesets
        end
      end
    end
  end
end
