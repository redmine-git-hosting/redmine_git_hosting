module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryUpdater < RepositoryHandler

      def call
        if configuration_exists?
          update_repository
        else
          logger.warn("#{action} : repository '#{gitolite_repo_name}' does not exist in Gitolite, exit !")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")
        end
      end


      private


        def update_repository
          logger.info("#{action} : repository '#{gitolite_repo_name}' exists in Gitolite, update it ...")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")

          # Update Gitolite repository
          update_repository_config
        end

    end
  end
end
