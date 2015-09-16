module RedmineGitHosting
  module Config
    module GitoliteNotifications
      extend self

      def gitolite_notify_global_prefix
        get_setting(:gitolite_notify_global_prefix)
      end


      def gitolite_notify_global_sender_address
        get_setting(:gitolite_notify_global_sender_address)
      end


      def gitolite_notify_global_include
        get_setting(:gitolite_notify_global_include)
      end


      def gitolite_notify_global_exclude
        get_setting(:gitolite_notify_global_exclude)
      end

    end
  end
end
