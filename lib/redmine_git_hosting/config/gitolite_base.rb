module RedmineGitHosting::Config

  module GitoliteBase

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      # Puts Redmine user in cache as it should not change
      @@redmine_user = nil
      def redmine_user
        @@redmine_user = (%x[whoami]).chomp.strip if @@redmine_user.nil?
        @@redmine_user
      end


      def gitolite_user
        RedmineGitHosting::Config.get_setting(:gitolite_user)
      end


      def gitolite_server_port
        RedmineGitHosting::Config.get_setting(:gitolite_server_port)
      end


      def gitolite_ssh_private_key
        RedmineGitHosting::Config.get_setting(:gitolite_ssh_private_key)
      end


      def gitolite_ssh_public_key
        RedmineGitHosting::Config.get_setting(:gitolite_ssh_public_key)
      end


      def gitolite_config_file
        RedmineGitHosting::Config.get_setting(:gitolite_config_file)
      end


      def gitolite_identifier_prefix
        RedmineGitHosting::Config.get_setting(:gitolite_identifier_prefix)
      end


      def gitolite_key_subdir
        'redmine_git_hosting'
      end


      def git_config_username
        RedmineGitHosting::Config.get_setting(:git_config_username)
      end


      def git_config_email
        RedmineGitHosting::Config.get_setting(:git_config_email)
      end


      def gitolite_temp_dir
        RedmineGitHosting::Config.get_setting(:gitolite_temp_dir)
      end


      def gitolite_url
        [gitolite_user, '@localhost'].join
      end


      def gitolite_admin_dir
        File.join(gitolite_temp_dir, gitolite_user, 'gitolite-admin.git')
      end


      def gitolite_log_level
        RedmineGitHosting::Config.get_setting(:gitolite_log_level)
      end

    end

  end
end
