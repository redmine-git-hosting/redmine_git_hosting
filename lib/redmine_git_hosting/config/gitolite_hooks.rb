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


      def gitolite_hooks_dir
        if gitolite_version == 3
          File.join(gitolite_home_dir, gitolite_local_code_dir, 'hooks', 'common')
        else
          File.join(gitolite_home_dir, '.gitolite', 'hooks', 'common')
        end
      end


      def check_hooks_install!
        {
          hook_files:    RedmineGitHosting::GitoliteHooks.hooks_installed?,
          global_params: RedmineGitHosting::GitoliteParams::GlobalParams.new.installed?,
          mailer_params: RedmineGitHosting::GitoliteParams::MailerParams.new.installed?
        }
      end


      def update_hook_params!
        GlobalParams.new.installed?
      end

    end

  end
end
