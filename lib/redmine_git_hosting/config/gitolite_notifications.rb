module RedmineGitHosting::Config

  module GitoliteNotifications

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_notify_global_prefix
        RedmineGitHosting::Config.get_setting(:gitolite_notify_global_prefix)
      end


      def gitolite_notify_global_sender_address
        RedmineGitHosting::Config.get_setting(:gitolite_notify_global_sender_address)
      end


      def gitolite_notify_global_include
        RedmineGitHosting::Config.get_setting(:gitolite_notify_global_include)
      end


      def gitolite_notify_global_exclude
        RedmineGitHosting::Config.get_setting(:gitolite_notify_global_exclude)
      end

    end

  end
end
