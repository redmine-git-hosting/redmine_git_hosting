require 'gitolite'

module RedmineGitolite

  module GitoliteWrapper

    # Used to register errors when pulling and pushing the conf file
    class GitoliteWrapperException < StandardError
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
    end


    # Puts Redmine user in cache as it should not change
    @@redmine_user = nil
    def self.redmine_user
      @@redmine_user = (%x[whoami]).chomp.strip if @@redmine_user.nil?
      @@redmine_user
    end


    def self.gitolite_user
      RedmineGitolite::Config.get_setting(:gitolite_user)
    end


    def self.gitolite_server_port
      RedmineGitolite::Config.get_setting(:gitolite_server_port)
    end


    def self.gitolite_ssh_private_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_private_key)
    end


    def self.gitolite_ssh_public_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_public_key)
    end


    def self.gitolite_config_file
      RedmineGitolite::Config.get_setting(:gitolite_config_file)
    end


    def self.gitolite_key_subdir
      'redmine_git_hosting'
    end


    def self.git_config_username
      RedmineGitolite::Config.get_setting(:git_config_username)
    end


    def self.git_config_email
      RedmineGitolite::Config.get_setting(:git_config_email)
    end


    def self.gitolite_temp_dir
      RedmineGitolite::Config.get_setting(:gitolite_temp_dir)
    end


    def self.http_server_domain
      RedmineGitolite::Config.get_setting(:http_server_domain)
    end


    def self.https_server_domain
      RedmineGitolite::Config.get_setting(:https_server_domain)
    end


    def self.gitolite_url
      [gitolite_user, '@localhost'].join
    end


    def self.gitolite_hooks_url
      [Setting.protocol, '://', Setting.host_name, '/githooks/post-receive/redmine'].join
    end


    def self.gitolite_admin_dir
      File.join(gitolite_temp_dir, gitolite_user, 'gitolite-admin.git')
    end


    ###############################
    ##                           ##
    ##      GITOLITE INFOS       ##
    ##                           ##
    ###############################

    def self.find_version(output)
      return 0 if output.blank?

      version = nil

      line = output.split("\n")[0]

      if line =~ /gitolite[ -]v?2./
        version = 2
      elsif line.include?('running gitolite3')
        version = 3
      else
        version = 0
      end

      return version
    end


    def self.gitolite_command
      if gitolite_version == 2
        gitolite_command = ['gl-setup']
      elsif gitolite_version == 3
        gitolite_command = ['gitolite', 'setup']
      else
        gitolite_command = nil
      end
      return gitolite_command
    end


    @@gitolite_version_cached = nil
    @@gitolite_version_stamp  = nil

    def self.gitolite_version
      if !@@gitolite_version_cached.nil? && (Time.new - @@gitolite_version_stamp <= 1)
        return @@gitolite_version_cached
      end

      logger.debug { "Getting Gitolite version..." }

      begin
        out, err, code = ssh_shell('info')
        @@gitolite_version_cached = find_version(out)
      rescue GitHosting::GitHostingException => e
        logger.error { "Error while getting Gitolite version" }
        @@gitolite_version_cached = -1
      end

      @@gitolite_version_stamp = Time.new
      return @@gitolite_version_cached
    end


    @@gitolite_banner_cached = nil
    @@gitolite_banner_stamp  = nil

    def self.gitolite_banner
      if !@@gitolite_banner_cached.nil? && (Time.new - @@gitolite_banner_stamp <= 1)
        return @@gitolite_banner_cached
      end

      logger.debug { "Getting Gitolite banner..." }

      begin
        @@gitolite_banner_cached = ssh_shell('info')[0]
      rescue GitHosting::GitHostingException => e
        logger.error { "Error while getting Gitolite banner" }
        @@gitolite_banner_cached = "Error : #{e.message}"
      end

      @@gitolite_banner_stamp = Time.new
      return @@gitolite_banner_cached
    end


    ##########################
    #                        #
    #   SUDO Shell Wrapper   #
    #                        #
    ##########################

    # Returns the sudo prefix to all sudo_* commands
    #
    # These are as follows:
    # * (-i) login as `gitolite_user` (setting ENV['HOME')
    # * (-n) non-interactive
    # * (-u `gitolite_user`) target user
    def self.sudo_shell_params
      ['-n', '-u', gitolite_user, '-i']
    end


    # Execute a command as the gitolite user defined in +GitoliteWrapper.gitolite_user+.
    #
    # Will shell out to +sudo -n -u <gitolite_user> params+
    #
    def self.sudo_shell(*params)
      GitHosting.execute('sudo', *sudo_shell_params.concat(params))
    end


    # Return only the output of the shell command
    # Throws an exception if the shell command does not exit with code 0.
    def self.sudo_capture(*params)
      GitHosting.capture('sudo', *sudo_shell_params.concat(params))
    end


    # Execute a command as the gitolite user defined in +GitoliteWrapper.gitolite_user+.
    #
    # Instead of capturing the command, it calls the block with the stdout pipe.
    # Raises an exception if the command does not exit with 0.
    #
    def self.sudo_pipe(*params, &block)
      GitHosting.pipe('sudo', *sudo_shell_params.concat(params), &block)
    end


    # Test if a file exists with size > 0
    def self.sudo_file_exists?(filename)
      sudo_test(filename, '-s')
    end


    # Test if a directory exists
    def self.sudo_dir_exists?(dirname)
      sudo_test(dirname, '-r')
    end


    # Test properties of a path from the git user.
    #
    # e.g., Test if a directory exists: sudo_test('~/somedir', '-d')
    def self.sudo_test(path, *testarg)
      out, _ , code = GitoliteWrapper.sudo_shell('eval', 'test', *testarg, path)
      return code == 0
    rescue => e
      logger.debug("File check for #{path} failed : #{e.message}")
      false
    end


    # Calls mkdir with the given arguments on the git user's side.
    #
    # e.g., sudo_mkdir('-p', '/some/path')
    #
    def self.sudo_mkdir(*args)
      sudo_shell('eval', 'mkdir', *args)
    end


    # Calls chmod with the given arguments on the git user's side.
    #
    # e.g., sudo_chmod('755', '/some/path')
    #
    def self.sudo_chmod(mode, file)
      sudo_shell('eval', 'chmod', mode, file)
    end


    # Removes a directory and all subdirectories below gitolite_user's $HOME.
    #
    # Assumes a relative path.
    #
    # If force=true, it will delete using 'rm -rf <path>', otherwise
    # it uses rmdir
    #
    def self.sudo_rmdir(path, force = false)
      if force
        sudo_shell('eval', 'rm', '-rf', path)
      else
        sudo_shell('eval', 'rmdir', path)
      end
    end


    # Moves a file/directory to a new target.
    #
    def self.sudo_move(old_path, new_path)
      sudo_shell('eval', 'mv', old_path, new_path)
    end


    # Test if repository is empty on Gitolite side
    #
    def self.sudo_repository_empty?(path)
      empty_repo = false

      path = File.join('$HOME', path, 'objects')

      begin
        output = sudo_capture('eval', 'find', path, '-type', 'f', '|', 'wc', '-l')
        logger.debug { "#{@action} : counted objects in repository directory '#{path}' : '#{output}'" }

        if output.to_i == 0
          empty_repo = true
        else
          empty_repo = false
        end
      rescue GitHosting::GitHostingException => e
        empty_repo = false
      end

      return empty_repo
    end


    ##########################
    #                        #
    #       SSH Wrapper      #
    #                        #
    ##########################

    # Execute a command in the gitolite forced environment through this user
    # i.e., executes 'ssh git@localhost <command>'
    #
    # Returns stdout, stderr and the exit code
    def self.ssh_shell(*params)
      GitHosting.execute('ssh', *ssh_shell_params.concat(params))
    end


    # Return only the output from the ssh command and checks
    def self.ssh_capture(*params)
      GitHosting.capture('ssh', *ssh_shell_params.concat(params))
    end

    # Returns the ssh prefix arguments for all ssh_* commands
    #
    # These are as follows:
    # * (-T) Never request tty
    # * (-i <gitolite_ssh_private_key>) Use the SSH keys given in Settings
    # * (-p <gitolite_server_port>) Use port from settings
    # * (-o BatchMode=yes) Never ask for a password
    # * <gitolite_user>@localhost (see +gitolite_url+)
    def self.ssh_shell_params
      ['-T', '-o', 'BatchMode=yes', '-p', gitolite_server_port, '-i', gitolite_ssh_private_key, gitolite_url]
    end


    ###############################
    ##                           ##
    ##         TEMP DIR          ##
    ##                           ##
    ###############################

    @@temp_dir_path = nil
    @@previous_temp_dir_path = nil

    def self.create_temp_dir
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

    def self.temp_dir_writeable?(opts = {})
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


    def self.http_root_url
      my_root_url(false)
    end


    def self.https_root_url
      my_root_url(true)
    end


    def self.my_root_url(ssl = false)
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
    ##        SUDO TESTS         ##
    ##                           ##
    ###############################

    ## SUDO TEST1

    @@sudo_gitolite_to_redmine_user_stamp = nil
    @@sudo_gitolite_to_redmine_user_cached = nil

    def self.can_gitolite_sudo_to_redmine_user?
      if !@@sudo_gitolite_to_redmine_user_cached.nil? && (Time.new - @@sudo_gitolite_to_redmine_user_stamp <= 1)
        return @@sudo_gitolite_to_redmine_user_cached
      end

      logger.info { "Testing if Gitolite user '#{gitolite_user}' can sudo to Redmine user '#{redmine_user}'..." }

      if gitolite_user == redmine_user
        @@sudo_gitolite_to_redmine_user_cached = true
        @@sudo_gitolite_to_redmine_user_stamp = Time.new
        logger.info { "OK!" }
        return @@sudo_gitolite_to_redmine_user_cached
      end

      begin
        test = sudo_capture('sudo', '-n', '-u', redmine_user, '-i', 'whoami')
        if test.match(/#{redmine_user}/)
          logger.info { "OK!" }
          @@sudo_gitolite_to_redmine_user_cached = true
          @@sudo_gitolite_to_redmine_user_stamp = Time.new
        else
          logger.warn { "Error while testing sudo_git_to_redmine_user" }
          @@sudo_gitolite_to_redmine_user_cached = false
          @@sudo_gitolite_to_redmine_user_stamp = Time.new
        end
      rescue GitHosting::GitHostingException => e
        logger.error { "Error while testing sudo_git_to_redmine_user" }
        @@sudo_gitolite_to_redmine_user_cached = false
        @@sudo_gitolite_to_redmine_user_stamp = Time.new
      end

      return @@sudo_gitolite_to_redmine_user_cached
    end


    ## SUDO TEST2

    @@sudo_redmine_to_gitolite_user_stamp = nil
    @@sudo_redmine_to_gitolite_user_cached = nil

    def self.can_redmine_sudo_to_gitolite_user?
      if !@@sudo_redmine_to_gitolite_user_cached.nil? && (Time.new - @@sudo_redmine_to_gitolite_user_stamp <= 1)
        return @@sudo_redmine_to_gitolite_user_cached
      end

      logger.info { "Testing if Redmine user '#{redmine_user}' can sudo to Gitolite user '#{gitolite_user}'..." }

      if gitolite_user == redmine_user
        @@sudo_redmine_to_gitolite_user_cached = true
        @@sudo_redmine_to_gitolite_user_stamp = Time.new
        logger.info { "OK!" }
        return @@sudo_redmine_to_gitolite_user_cached
      end

      begin
        test = sudo_capture('whoami')
        if test.match(/#{gitolite_user}/)
          logger.info { "OK!" }
          @@sudo_redmine_to_gitolite_user_cached = true
          @@sudo_redmine_to_gitolite_user_stamp = Time.new
        else
          logger.warn { "Error while testing sudo_web_to_gitolite_user" }
          @@sudo_redmine_to_gitolite_user_cached = false
          @@sudo_redmine_to_gitolite_user_stamp = Time.new
        end
      rescue GitHosting::GitHostingException => e
        logger.error { "Error while testing sudo_web_to_gitolite_user" }
        @@sudo_redmine_to_gitolite_user_cached = false
        @@sudo_redmine_to_gitolite_user_stamp = Time.new
      end

      return @@sudo_redmine_to_gitolite_user_cached
    end


    ###############################
    ##                           ##
    ##          MIRRORS          ##
    ##                           ##
    ###############################

    GITOLITE_MIRRORING_KEYS_NAME   = "redmine_gitolite_admin_id_rsa_mirroring"


    def self.gitolite_ssh_private_key_dest_path
      File.join('$HOME', '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
    end


    def self.gitolite_ssh_public_key_dest_path
      File.join('$HOME', '.ssh', "#{GITOLITE_MIRRORING_KEYS_NAME}.pub")
    end


    def self.gitolite_mirroring_script_dest_path
      File.join('$HOME', '.ssh', 'run_gitolite_admin_ssh')
    end


    @@mirroring_public_key = nil

    def self.mirroring_public_key
      if @@mirroring_public_key.nil?
        begin
          public_key = File.read(gitolite_ssh_public_key).chomp.strip
          @@mirroring_public_key = public_key.split(/[\t ]+/)[0].to_s + " " + public_key.split(/[\t ]+/)[1].to_s
        rescue => e
          logger.error { "Error while loading mirroring public key : #{e.output}" }
          @@mirroring_public_key = nil
        end
      end

      return @@mirroring_public_key
    end


    @@mirroring_keys_installed = false

    def self.mirroring_keys_installed?(opts = {})
      @@mirroring_keys_installed = false if opts.has_key?(:reset) && opts[:reset] == true

      if !@@mirroring_keys_installed
        logger.info { "Installing Redmine Gitolite mirroring SSH keys ..." }

        command = ['#!/bin/sh', "\n", 'exec', 'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-i', gitolite_ssh_private_key_dest_path, '"$@"'].join(' ')

        begin
          sudo_pipe("sh") do
            [ 'echo', "'" + File.read(gitolite_ssh_private_key).chomp.strip + "'", '>', gitolite_ssh_private_key_dest_path ].join(' ')
          end

          sudo_pipe("sh") do
            [ 'echo', "'" + File.read(gitolite_ssh_public_key).chomp.strip + "'", '>', gitolite_ssh_public_key_dest_path ].join(' ')
          end

          sudo_pipe("sh") do
            [ 'echo', "'" + command + "'", '>', gitolite_mirroring_script_dest_path ].join(' ')
          end

          sudo_chmod('600', gitolite_ssh_private_key_dest_path)
          sudo_chmod('644', gitolite_ssh_public_key_dest_path)
          sudo_chmod('700', gitolite_mirroring_script_dest_path)

          logger.info { "Done !" }

          @@mirroring_keys_installed = true
        rescue GitHosting::GitHostingException => e
          logger.error { "Failed installing Redmine Gitolite mirroring SSH keys ! (#{e.output})" }
          @@mirroring_keys_installed = false
        end
      end

      return @@mirroring_keys_installed
    end


    ##########################
    #                        #
    #   Gitolite Accessor    #
    #                        #
    ##########################

    def self.gitolite_admin_settings
      {
        git_user: gitolite_user,
        host: "localhost:#{gitolite_server_port}",

        author_name: git_config_username,
        author_email: git_config_email,

        public_key: gitolite_ssh_public_key,
        private_key: gitolite_ssh_private_key,

        key_subdir: gitolite_key_subdir,
        config_file: gitolite_config_file
      }
    end


    def self.admin
      create_temp_dir
      admin_dir = gitolite_admin_dir
      logger.info { "Acessing gitolite-admin.git at '#{admin_dir}'" }
      begin
        Gitolite::GitoliteAdmin.new(admin_dir, gitolite_admin_settings)
      rescue => e
        logger.error { e.message }
        return nil
      end
    end


    WRAPPERS = [GitoliteWrapper::Admin, GitoliteWrapper::Repositories,
      GitoliteWrapper::Users, GitoliteWrapper::Projects]

    # Update the Gitolite Repository
    #
    # action: An API action defined in one of the gitolite/* classes.
    def self.update(action, object, options = {})
      options = options.symbolize_keys

      if options.has_key?(:flush_cache) && options[:flush_cache] == true
        logger.info { "Flush Settings Cache !" }
        Setting.check_cache
      end

      WRAPPERS.each do |wrappermod|
        if wrappermod.method_defined?(action)
          return wrappermod.new(action, object, options).send(action)
        end
      end

      raise GitoliteWrapperException.new(action, "No available Wrapper for action '#{action}' found.")
    end

  end
end
