module RedmineGitolite::GitoliteModules

  module GitoliteConfig

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def logger
        RedmineGitolite::Log.get_logger(:global)
      end

      # Puts Redmine user in cache as it should not change
      @@redmine_user = nil
      def redmine_user
        @@redmine_user = (%x[whoami]).chomp.strip if @@redmine_user.nil?
        @@redmine_user
      end


      def gitolite_user
        RedmineGitolite::Config.get_setting(:gitolite_user)
      end


      def gitolite_server_port
        RedmineGitolite::Config.get_setting(:gitolite_server_port)
      end


      def gitolite_ssh_private_key
        RedmineGitolite::Config.get_setting(:gitolite_ssh_private_key)
      end


      def gitolite_ssh_public_key
        RedmineGitolite::Config.get_setting(:gitolite_ssh_public_key)
      end


      def gitolite_config_file
        RedmineGitolite::Config.get_setting(:gitolite_config_file)
      end


      def gitolite_key_subdir
        'redmine_git_hosting'
      end


      def git_config_username
        RedmineGitolite::Config.get_setting(:git_config_username)
      end


      def git_config_email
        RedmineGitolite::Config.get_setting(:git_config_email)
      end


      def gitolite_temp_dir
        RedmineGitolite::Config.get_setting(:gitolite_temp_dir)
      end


      def http_server_domain
        RedmineGitolite::Config.get_setting(:http_server_domain)
      end


      def https_server_domain
        RedmineGitolite::Config.get_setting(:https_server_domain)
      end


      def gitolite_url
        [gitolite_user, '@localhost'].join
      end


      def gitolite_hooks_url
        [Setting.protocol, '://', Setting.host_name, '/githooks/post-receive/redmine'].join
      end


      def gitolite_admin_dir
        File.join(gitolite_temp_dir, gitolite_user, 'gitolite-admin.git')
      end


      def http_root_url
        my_root_url(false)
      end


      def https_root_url
        my_root_url(true)
      end


      def my_root_url(ssl = false)
        # Remove any path from httpServer in case they are leftover from previous installations.
        # No trailing /.
        my_root_path = Redmine::Utils::relative_url_root

        if ssl && https_server_domain != ''
          server_domain = https_server_domain
        else
          server_domain = http_server_domain
        end

        my_root_url = File.join(server_domain[/^[^\/]*/], my_root_path, "/")[0..-2]

        return my_root_url
      end


      ###############################
      ##                           ##
      ##         TEMP DIR          ##
      ##                           ##
      ###############################

      @@temp_dir_path = nil
      @@previous_temp_dir_path = nil

      def create_temp_dir
        if (@@previous_temp_dir_path != gitolite_temp_dir)
          @@previous_temp_dir_path = gitolite_temp_dir
          @@temp_dir_path = gitolite_admin_dir
        end

        if !File.directory?(@@temp_dir_path)
          logger.info { "Create tmp directory : '#{@@temp_dir_path}'" }

          begin
            FileUtils.mkdir_p @@temp_dir_path
            FileUtils.chmod 0700, @@temp_dir_path
          rescue => e
            logger.error { "Cannot create tmp directory : '#{@@temp_dir_path}'" }
          end

        end

        return @@temp_dir_path
      end


      @@temp_dir_writeable = false

      def temp_dir_writeable?(opts = {})
        @@temp_dir_writeable = false if opts.has_key?(:reset) && opts[:reset] == true

        if !@@temp_dir_writeable

          logger.debug { "Testing if temp directory '#{create_temp_dir}' is writeable ..." }

          mytestfile = File.join(create_temp_dir, "writecheck")

          if !File.directory?(create_temp_dir)
            @@temp_dir_writeable = false
          else
            begin
              FileUtils.touch mytestfile
              FileUtils.rm mytestfile
              @@temp_dir_writeable = true
            rescue => e
              @@temp_dir_writeable = false
            end
          end
        end

        return @@temp_dir_writeable
      end

    end

  end
end
