module PluginSettingsValidation
  module SshConfig
    extend ActiveSupport::Concern

    included do
      # Gitolite SSH Config
      add_accessor :gitolite_user,
                   :gitolite_server_host,
                   :gitolite_server_port,
                   :gitolite_ssh_private_key,
                   :gitolite_ssh_public_key

      before_validation do
        self.gitolite_user        = strip_value(gitolite_user)
        self.gitolite_server_host = strip_value(gitolite_server_host)
        self.gitolite_server_port = strip_value(gitolite_server_port)

        self.gitolite_ssh_private_key = strip_value(gitolite_ssh_private_key)
        self.gitolite_ssh_public_key  = strip_value(gitolite_ssh_public_key)
      end

      validates :gitolite_user,            presence: true
      validates :gitolite_server_host,     presence: true
      validates :gitolite_server_port,     presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65_536 }
      validates :gitolite_ssh_private_key, presence: true
      validates :gitolite_ssh_public_key,  presence: true

      validates_each :gitolite_ssh_private_key, :gitolite_ssh_public_key do |record, attr, value|
        record.errors.add(attr, 'must exists on filesystem') unless File.exists?(value)
      end
    end
  end
end
