module PluginSettingsValidation
  module HooksConfig
    extend ActiveSupport::Concern

    included do
      # Gitolite Hooks Config
      add_accessor :gitolite_overwrite_existing_hooks,
                   :gitolite_hooks_are_asynchronous,
                   :gitolite_hooks_debug,
                   :gitolite_hooks_url

      before_validation do
        self.gitolite_hooks_url = strip_value(gitolite_hooks_url)
      end

      validates :gitolite_overwrite_existing_hooks, presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_hooks_are_asynchronous,   presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_hooks_debug,              presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_hooks_url,                presence: true, format:    { with: URI::regexp(%w[http https]) }
    end
  end
end
