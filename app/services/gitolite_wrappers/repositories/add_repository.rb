module GitoliteWrappers
  module Repositories
    class AddRepository < GitoliteWrappers::Base
      unloadable

      def call
        if !repository.nil?
          create_repository
        else
          log_object_dont_exist
        end
      end


      def repository
        @repository ||= Repository.find_by_id(object_id)
      end


      def create_repository
        admin.transaction do
          create_gitolite_repository(repository)
          gitolite_admin_repo_commit(repository.gitolite_repository_name)

          @recovered = RedmineGitHosting::Recycle.recover_repository_if_present?(repository)

          if !@recovered
            logger.info("#{context} : let Gitolite create empty repository '#{repository.gitolite_repository_path}'")
          else
            logger.info("#{context} : restored existing Gitolite repository '#{repository.gitolite_repository_path}' for update")
          end
        end

        # Call Gitolite plugins
        logger.info('Execute Gitolite Plugins')

        # Create README file or initialize GitAnnex
        RedmineGitHosting::Plugins.execute(:post_create, repository, options.merge(recovered: @recovered))

        # Fetch changeset
        repository.fetch_changesets
      end

    end
  end
end
