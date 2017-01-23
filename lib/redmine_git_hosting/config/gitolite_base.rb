require 'etc'

module RedmineGitHosting
  module Config
    module GitoliteBase
      extend self

      def check_cache
        @gitolite_home_dir        = nil
        @mirroring_keys_installed = nil
        @mirroring_public_key     = nil
        @gitolite_ssh_fingerprint = nil
      end


      def redmine_user
        @redmine_user ||= (%x[whoami]).chomp.strip
      end


      def gitolite_use_sudo?
        redmine_user != gitolite_user
      end


      def gitolite_home_dir
        @gitolite_home_dir ||= Etc.getpwnam(gitolite_user).dir rescue nil
      end


      def gitolite_bin_dir
        @gitolite_bin_dir ||= RedmineGitHosting::Commands.sudo_gitolite_query_rc('GL_BINDIR')
      end


      def gitolite_lib_dir
        @gitolite_lib_dir ||= RedmineGitHosting::Commands.sudo_gitolite_query_rc('GL_LIBDIR')
      end


      def gitolite_user
        get_setting(:gitolite_user)
      end


      def gitolite_server_host
        get_setting(:gitolite_server_host)
      end


      def gitolite_server_port
        get_setting(:gitolite_server_port)
      end


      def gitolite_ssh_private_key
        get_setting(:gitolite_ssh_private_key)
      end


      def gitolite_ssh_public_key
        get_setting(:gitolite_ssh_public_key)
      end


      def gitolite_ssh_public_key_fingerprint
        @gitolite_ssh_fingerprint ||= RedmineGitHosting::Utils::Ssh.ssh_fingerprint(File.read(gitolite_ssh_public_key))
      end


      def gitolite_config_file
        File.basename(get_setting(:gitolite_config_file))
      end


      def gitolite_config_dir
        dirs = File.dirname(gitolite_config_file).split('/')
        if dirs[0] != '.'
          File.join('conf', *dirs)
        else
          'conf'
        end
      end


      def gitolite_identifier_prefix
        get_setting(:gitolite_identifier_prefix)
      end


      def gitolite_identifier_strip_user_id?
        get_setting(:gitolite_identifier_strip_user_id, true)
      end


      def gitolite_key_subdir
        'redmine_git_hosting'
      end


      def git_config_username
        get_setting(:git_config_username)
      end


      def git_config_email
        get_setting(:git_config_email)
      end


      def gitolite_temp_dir
        get_setting(:gitolite_temp_dir)
      end


      def gitolite_url
        [gitolite_user, '@', gitolite_server_host].join
      end


      def gitolite_admin_dir
        File.join(gitolite_temp_dir, gitolite_user, 'gitolite-admin.git')
      end


      def gitolite_log_level
        get_setting(:gitolite_log_level)
      end

    end
  end
end
