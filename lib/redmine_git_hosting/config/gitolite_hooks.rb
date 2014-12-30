module RedmineGitHosting::Config

  module GitoliteHooks

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_hooks_namespace
        'redminegitolite'
      end


      def gitolite_hooks_url
        [RedmineGitHosting::Config.get_setting(:gitolite_hooks_url), '/githooks/post-receive/redmine'].join
      end


      def gitolite_hooks_debug
        RedmineGitHosting::Config.get_setting(:gitolite_hooks_debug, true)
      end


      def gitolite_hooks_are_asynchronous
        RedmineGitHosting::Config.get_setting(:gitolite_hooks_are_asynchronous, true)
      end


      def gitolite_force_hooks_update?
        RedmineGitHosting::Config.get_setting(:gitolite_force_hooks_update, true)
      end


      def gitolite_local_code_dir
        RedmineGitHosting::Config.get_setting(:gitolite_local_code_dir)
      end

    end

  end
end
