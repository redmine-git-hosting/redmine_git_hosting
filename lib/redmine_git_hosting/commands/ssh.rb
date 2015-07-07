module RedmineGitHosting
  module Commands
    module Ssh
      extend self

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
      #
      def ssh_shell(*params)
        cmd = ssh.concat(params)
        execute(cmd)
      end


      private


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
        # * <gitolite_user>@<gitolite_server_host> (see +gitolite_url+)
        #
        def ssh_shell_params
          [
            '-T',
            '-o', 'BatchMode=yes',
            '-o', 'UserKnownHostsFile=/dev/null',
            '-o', 'StrictHostKeyChecking=no',
            '-p', RedmineGitHosting::Config.gitolite_server_port,
            '-i', RedmineGitHosting::Config.gitolite_ssh_private_key,
            RedmineGitHosting::Config.gitolite_url
          ]
        end

    end
  end
end
