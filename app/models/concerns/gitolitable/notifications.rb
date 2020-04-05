module Gitolitable
  module Notifications
    extend ActiveSupport::Concern

    def mailing_list
      default_list + global_include_list - global_exclude_list
    end

    def default_list
      watcher_users.map(&:email_address).map(&:address)
    end

    def global_include_list
      RedmineGitHosting::Config.gitolite_notify_global_include
    end

    def global_exclude_list
      RedmineGitHosting::Config.gitolite_notify_global_exclude
    end

    def sender_address
      extra.notification_sender.presence || RedmineGitHosting::Config.gitolite_notify_global_sender_address
    end

    def email_prefix
      extra.notification_prefix.presence || RedmineGitHosting::Config.gitolite_notify_global_prefix
    end
  end
end
