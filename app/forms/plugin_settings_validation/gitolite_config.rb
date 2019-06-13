module PluginSettingsValidation
  module GitoliteConfig
    extend ActiveSupport::Concern

    included do
      # Gitolite Config File
      add_accessor :gitolite_config_file,
                   :gitolite_identifier_prefix,
                   :gitolite_identifier_strip_user_id

      # Gitolite Global Config
      add_accessor :gitolite_temp_dir,
                   :gitolite_recycle_bin_expiration_time,
                   :gitolite_log_level,
                   :git_config_username,
                   :git_config_email

      before_validation do
        self.gitolite_config_file       = strip_value(gitolite_config_file)
        self.gitolite_identifier_prefix = strip_value(gitolite_identifier_prefix)
        self.gitolite_temp_dir          = strip_value(gitolite_temp_dir)
        self.git_config_username        = strip_value(git_config_username)
        self.git_config_email           = strip_value(git_config_email)
        self.gitolite_recycle_bin_expiration_time = strip_value(gitolite_recycle_bin_expiration_time)
      end

      # Validates Gitolite Config File
      validates :gitolite_identifier_strip_user_id, presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }

      # Validates Gitolite Global Config
      validates :gitolite_temp_dir, presence: true
      validates :gitolite_recycle_bin_expiration_time, presence: true, numericality: true

      validates :gitolite_log_level,  presence: true, inclusion: { in: RedmineGitHosting::Logger::LOG_LEVELS }
      validates :git_config_username, presence: true
      validates :git_config_email,    presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

      validate  :gitolite_config_file_is_relative
      validate  :tmp_dir_is_absolute

      after_validation do
        self.gitolite_recycle_bin_expiration_time = convert_time(gitolite_recycle_bin_expiration_time)

        if gitolite_config_file == RedmineGitHosting::Config::GITOLITE_DEFAULT_CONFIG_FILE
          self.gitolite_identifier_strip_user_id = 'false'
          self.gitolite_identifier_prefix = RedmineGitHosting::Config::GITOLITE_IDENTIFIER_DEFAULT_PREFIX
        end
      end
    end

    private

    def gitolite_config_file_is_relative
      errors.add(:gitolite_config_file, 'must be relative') if gitolite_config_file.starts_with?('/')
    end

    def tmp_dir_is_absolute
      errors.add(:gitolite_temp_dir, 'must be absolute') unless gitolite_temp_dir.starts_with?('/')
    end
  end
end
