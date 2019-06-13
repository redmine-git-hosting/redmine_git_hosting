module PluginSettingsValidation
  module GitoliteAccessConfig
    extend ActiveSupport::Concern

    included do
      # Gitolite Access Config
      add_accessor :ssh_server_domain,
                   :http_server_domain,
                   :https_server_domain,
                   :http_server_subdir,
                   :show_repositories_url,
                   :gitolite_daemon_by_default,
                   :gitolite_http_by_default

      before_validation do
        self.ssh_server_domain   = strip_value(ssh_server_domain)
        self.http_server_domain  = strip_value(http_server_domain)
        self.https_server_domain = strip_value(https_server_domain)
        self.http_server_subdir  = strip_value(http_server_subdir)
      end

      validates :ssh_server_domain,   presence: true, format: { with: RedmineGitHosting::Validators::DOMAIN_REGEX }
      validates :http_server_domain,  presence: true, format: { with: RedmineGitHosting::Validators::DOMAIN_REGEX }
      validates :https_server_domain, format: { with: RedmineGitHosting::Validators::DOMAIN_REGEX }, allow_blank: true

      validates :show_repositories_url,      presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_daemon_by_default, presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_http_by_default,   presence: true, inclusion: { in: %w[0 1 2 3] }, numericality: { only_integer: true }

      validate  :http_server_subdir_is_relative
    end

    private

    def http_server_subdir_is_relative
      errors.add(:http_server_subdir, 'must be relative') if http_server_subdir.starts_with?('/')
    end
  end
end
