require 'gitolite'
require 'open3'

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


    def self.gitolite_command
      if gitolite_version == 2
        'gl-setup'
      else
        'gitolite setup'
      end
    end


    def self.gitolite_version
      Rails.cache.fetch(GitHosting.cache_key('gitolite_version')) do
        logger.debug("Updating Gitolite version")
        out, err, code = ssh_shell('info')
        return 3 if out.include?('running gitolite3')
        return 2 if out =~ /gitolite[ -]v?2./
        logger.error("Couldn't retrieve gitolite version through SSH.")
        logger.debug("Gitolite version error output: #{err}") unless err.nil?
      end
    end


    # Returns the gitolite welcome/info banner, containing its version.
    #
    # Upon error, returns the shell error code instead.
    def self.gitolite_banner
      Rails.cache.fetch(GitHosting.cache_key('gitolite_banner')) {
        logger.debug("Retrieving gitolite banner")
        begin
          GitoliteWrapper.ssh_capture('info')
        rescue => e
          errstr = "Error while getting Gitolite banner: #{e.message}"
          logger.error(errstr)
          errstr
        end
      }
    end


    def self.gitolite_home_dir
      sudo_capture('pwd').chomp.strip
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
      ['-i', '-n', '-u', gitolite_user]
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
      Open3.popen3("sudo", *sudo_shell_params.concat(params))  do |stdin, stdout, stderr, thr|
        begin
          exitcode = thr.value.exitstatus
          if exitcode != 0
            logger.error("sudo call with '#{params.join(" ")}' returned exit #{exitcode}. Error was: #{stderr.read}")
          else
            block.call(stdout)
          end
        ensure
          stdout.close
          stdin.close
        end
      end
    end


    def self.pipe_sudo(pipe_command, data, sudo_command)
      runner = RedmineGitolite::Scripts.shell_cmd_script_path

      command = [pipe_command, data, '|', runner, sudo_command, '2>&1'].join(' ')

      logger.debug { command }

      return GitHosting.execute(command)
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
      out, _ , code = GitoliteWrapper.sudo_shell('test', *testarg, path)
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
      sudo_capture('mkdir', *args)
    end


    # Calls chmod with the given arguments on the git user's side.
    #
    # e.g., sudo_chmod('755', '/some/path')
    #
    def self.sudo_chmod(mode, file)
      sudo_capture('chmod', mode, file)
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
        sudo_capture('rm', '-rf', path)
      else
        sudo_capture('rmdir', path)
      end
    end


    # Moves a file/directory to a new target.
    #
    def self.sudo_move(old_path, new_path)
      sudo_capture('mv', old_path, new_path)
    end


    # Test if repository is empty on Gitolite side
    #
    def self.sudo_repository_empty?(path)
      empty_repo = false

      path = File.join(path, 'objects')

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
      GitHosting.shell2('ssh', *ssh_shell_params.concat(params))
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


    ##########################
    #                        #
    #  Config Tests / Setup  #
    #                        #
    ##########################


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
      admin_dir = gitolite_admin_dir
      logger.info { "Acessing gitolite-admin.git at '#{admin_dir}'" }
      Gitolite::GitoliteAdmin.new(admin_dir, gitolite_admin_settings)
    end


    WRAPPERS = [GitoliteWrapper::Admin, GitoliteWrapper::Repositories,
      GitoliteWrapper::Users, GitoliteWrapper::Projects]

    # Update the Gitolite Repository
    #
    # action: An API action defined in one of the gitolite/* classes.
    def self.update(action, object, options={})
      WRAPPERS.each do |wrappermod|
        if wrappermod.method_defined?(action)
          return wrappermod.new(action, object, options).send(action)
        end
      end

      raise GitoliteWrapperException.new(action, "No available Wrapper for action '#{action}' found.")
    end

  end
end
