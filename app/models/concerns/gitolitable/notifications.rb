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
      if extra.notification_sender.nil? || extra.notification_sender.empty?
        RedmineGitHosting::Config.gitolite_notify_global_sender_address
      else
        extra.notification_sender
      end
    end


    def email_prefix
      if extra.notification_prefix.nil? || extra.notification_prefix.empty?
        RedmineGitHosting::Config.gitolite_notify_global_prefix
      else
        extra.notification_prefix
      end
    end

  end
end
