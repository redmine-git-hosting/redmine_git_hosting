module PluginSettingsValidation
  module MailingListConfig
    extend ActiveSupport::Concern

    included do
      # Git Mailing List Config
      add_accessor :gitolite_notify_by_default,
                   :gitolite_notify_global_prefix,
                   :gitolite_notify_global_sender_address,
                   :gitolite_notify_global_include,
                   :gitolite_notify_global_exclude

      before_validation do
        self.gitolite_notify_global_include = filter_email_list(gitolite_notify_global_include)
        self.gitolite_notify_global_exclude = filter_email_list(gitolite_notify_global_exclude)
      end

      validates :gitolite_notify_by_default,            presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_notify_global_sender_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      validate  :git_notifications_intersection
    end

    private

    # Validate intersection of global_include/global_exclude
    #
    def git_notifications_intersection
      intersection = gitolite_notify_global_include & gitolite_notify_global_exclude
      return unless intersection.count.positive?

      errors.add(:base, 'duplicated entries detected in gitolite_notify_global_include and gitolite_notify_global_exclude')
    end
  end
end
