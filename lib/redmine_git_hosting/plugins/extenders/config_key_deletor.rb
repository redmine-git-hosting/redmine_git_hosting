# frozen_string_literal: true

module RedmineGitHosting::Plugins::Extenders
  class ConfigKeyDeletor < BaseExtender
    attr_reader :delete_git_config_key

    def initialize(repository, **options)
      super(repository, **options)
      @delete_git_config_key = options.delete(:delete_git_config_key) { '' }
    end

    def post_update
      # Delete hook param if needed
      delete_hook_param if delete_git_config_key.present?
    end

    private

    def delete_hook_param
      sudo_git 'config', '--local', '--unset', delete_git_config_key
    rescue RedmineGitHosting::Error::GitoliteCommandException
      logger.error "Error while deleting Git config key '#{delete_git_config_key}' for repository '#{gitolite_repo_name}'"
    else
      logger.info "Git config key '#{delete_git_config_key}' successfully deleted for repository '#{gitolite_repo_name}'"
    end
  end
end
