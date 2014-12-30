module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryBranchUpdater

      attr_reader :repository
      attr_reader :gitolite_repo_name
      attr_reader :gitolite_repo_path
      attr_reader :default_branch


      def initialize(repository)
        @repository         = repository
        @gitolite_repo_name = repository.gitolite_repository_name
        @gitolite_repo_path = repository.gitolite_repository_path
        @default_branch     = repository.default_branch
      end


      def call
        update_default_branch
        clear_cache
        fetch_changesets
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def update_default_branch
          begin
            RedmineGitHosting::Commands.sudo_capture(*git_command)
          rescue RedmineGitHosting::GitHosting::GitHostingException => e
            logger.error("Error while updating default branch for repository '#{gitolite_repo_name}'")
          else
            logger.info("Default branch successfully updated for repository '#{gitolite_repo_name}'")
          end
        end


        def git_command
          [ 'git', "--git-dir=#{gitolite_repo_path}", 'symbolic-ref', 'HEAD', new_default_branch ]
        end


        def new_default_branch
          "refs/heads/#{default_branch}"
        end


        def clear_cache
          RedmineGitHosting::CacheManager.clear_cache_for_repository(repository)
        end


        def fetch_changesets
          logger.info("Fetch changesets for repository '#{gitolite_repo_name}'")
          repository.fetch_changesets
        end

    end
  end
end
