module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryBranchUpdater

      attr_reader :repository

      def initialize(repository)
        @repository = repository
      end


      def call
        update_default_branch
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def update_default_branch
          begin
            RedmineGitHosting::GitoliteWrapper.sudo_capture('git', "--git-dir=#{repository.gitolite_repository_path}", 'symbolic-ref', 'HEAD', "refs/heads/#{repository.extra[:default_branch]}")
            logger.info("Default branch successfully updated for repository '#{repository.gitolite_repository_name}'")
          rescue RedmineGitHosting::GitHosting::GitHostingException => e
            logger.error("Error while updating default branch for repository '#{repository.gitolite_repository_name}'")
          end

          RedmineGitHosting::CacheManager.clear_cache_for_repository(repository)

          logger.info("Fetch changesets for repository '#{repository.gitolite_repository_name}'")
          repository.fetch_changesets
        end

    end
  end
end
