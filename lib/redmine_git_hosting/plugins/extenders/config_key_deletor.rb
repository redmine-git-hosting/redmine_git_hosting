module RedmineGitHosting::Plugins::Extenders
  class ConfigKeyDeletor < BaseExtender

    attr_reader :delete_git_config_key


    def initialize(*args)
      super
      @delete_git_config_key = options.delete(:delete_git_config_key) { '' }
    end


    def post_update
      # Delete hook param if needed
      delete_hook_param unless delete_git_config_key.nil? || delete_git_config_key.empty?
    end


    private


      def delete_hook_param
        begin
          sudo_git('config', '--local', '--unset', delete_git_config_key)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Error while deleting Git config key '#{delete_git_config_key}' for repository '#{gitolite_repo_name}'")
        else
          logger.info("Git config key '#{delete_git_config_key}' successfully deleted for repository '#{gitolite_repo_name}'")
        end
      end

  end
end
