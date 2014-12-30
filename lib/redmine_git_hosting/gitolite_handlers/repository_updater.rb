module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryUpdater < RepositoryHandler

      attr_reader :delete_git_config_key


      def initialize(*args)
        super
        @delete_git_config_key = opts.delete(:delete_git_config_key){ '' }
      end


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

          # Delete hook param if needed
          delete_hook_param unless delete_git_config_key.empty?
        end


        def delete_hook_param
          begin
            RedmineGitHosting::Commands.sudo_capture(*git_command)
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Error while deleting Git config key '#{delete_git_config_key}' for repository '#{gitolite_repo_name}'")
          else
            logger.info("Git config key '#{delete_git_config_key}' successfully deleted for repository '#{gitolite_repo_name}'")
          end
        end


        def git_command
          [ 'git', "--git-dir=#{gitolite_repo_path}", 'config', '--local', '--unset', delete_git_config_key ]
        end

    end
  end
end
