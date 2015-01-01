require 'digest/md5'

module RedmineGitHosting
  module Commands

    include Commands::Git
    include Commands::Gitolite
    include Commands::Sudo


    class << self

      # Return only the output of the shell command.
      # Throws an exception if the shell command does not exit with code 0.
      #
      def sudo_capture(*params)
        cmd = sudo.concat(params)
        capture(cmd)
      end


      # Execute a command as the gitolite user defined in +GitoliteWrapper.gitolite_user+.
      #
      # Will shell out to +sudo -n -u <gitolite_user> params+
      #
      def sudo_shell(*params)
        cmd = sudo.concat(params)
        execute(cmd)
      end


      # Write data on stdin and return the output of the shell command.
      # Throws an exception if the shell command does not exit with code 0.
      #
      def sudo_pipe_data(stdin)
        cmd = sudo.push('sh')
        capture(cmd, {stdin_data: stdin, binmode: true})
      end


      # Return only the output from the ssh command.
      #
      def ssh_capture(*params)
        cmd = ssh.concat(params)
        capture(cmd)
      end


      # Execute a command in the gitolite forced environment through this user
      # i.e., executes 'ssh git@localhost <command>'
      #
      # Returns stdout, stderr and the exit code
      def ssh_shell(*params)
        cmd = ssh.concat(params)
        execute(cmd)
      end


      # Wrapper to Open3.capture.
      #
      def capture(args = [], opts = {})
        cmd = args.shift
        RedmineGitHosting::Utils.capture(cmd, args, opts)
      end


      # Wrapper to Open3.capture.
      #
      def execute(args = [], opts = {})
        cmd = args.shift
        RedmineGitHosting::Utils.execute(cmd, args, opts)
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def gitolite_command
          RedmineGitHosting::Config.gitolite_command
        end


        def gitolite_home_dir
          RedmineGitHosting::Config.gitolite_home_dir
        end


        # Return the SSH command with basic args
        #
        def ssh
          ['ssh', *ssh_shell_params]
        end


        # Returns the ssh prefix arguments for all ssh_* commands.
        #
        # These are as follows:
        # * (-T) Never request tty
        # * (-i <gitolite_ssh_private_key>) Use the SSH keys given in Settings
        # * (-p <gitolite_server_port>) Use port from settings
        # * (-o BatchMode=yes) Never ask for a password
        # * <gitolite_user>@localhost (see +gitolite_url+)
        def ssh_shell_params
          [
            '-T', '-o', 'BatchMode=yes',
            '-p', RedmineGitHosting::Config.gitolite_server_port,
            '-i', RedmineGitHosting::Config.gitolite_ssh_private_key,
            RedmineGitHosting::Config.gitolite_url
          ]
        end


        # Return the Sudo command with basic args.
        #
        def sudo
          ['sudo', *sudo_shell_params]
        end


        # Returns the sudo prefix to all sudo_* commands.
        #
        # These are as follows:
        # * (-i) login as `gitolite_user` (setting ENV['HOME')
        # * (-n) non-interactive
        # * (-u `gitolite_user`) target user
        #
        def sudo_shell_params
          ['-n', '-u', RedmineGitHosting::Config.gitolite_user, '-i']
        end


        # Return the Git command with prepend args (mainly env vars like FOO=BAR git push).
        #
        def git(args = [])
          [*args, 'git']
        end


        # Return a md5 hash of the string passed.
        #
        def hash_content(content)
          Digest::MD5.hexdigest(content)
        end


        # Return the content of a local (Redmine side) file.
        #
        def local_content(file)
          File.read(file)
        end


        # Return the content of a file on Gitolite sides.
        #
        def distant_content(destination_path)
          sudo_capture('cat', destination_path) rescue ''
        end

    end

  end
end
