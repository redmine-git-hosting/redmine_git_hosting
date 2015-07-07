module RedmineGitHosting
  module Config
    module GitoliteNotifications
      extend self

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
