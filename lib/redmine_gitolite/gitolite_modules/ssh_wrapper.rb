module RedmineGitolite::GitoliteModules

  module SshWrapper

    ##########################
    #                        #
    #       SSH Wrapper      #
    #                        #
    ##########################

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      # Execute a command in the gitolite forced environment through this user
      # i.e., executes 'ssh git@localhost <command>'
      #
      # Returns stdout, stderr and the exit code
      def ssh_shell(*params)
        RedmineGitolite::GitHosting.execute('ssh', ssh_shell_params.concat(params))
      end


      # Return only the output from the ssh command and checks
      def ssh_capture(*params)
        RedmineGitolite::GitHosting.capture('ssh', ssh_shell_params.concat(params))
      end

      # Returns the ssh prefix arguments for all ssh_* commands
      #
      # These are as follows:
      # * (-T) Never request tty
      # * (-i <gitolite_ssh_private_key>) Use the SSH keys given in Settings
      # * (-p <gitolite_server_port>) Use port from settings
      # * (-o BatchMode=yes) Never ask for a password
      # * <gitolite_user>@localhost (see +gitolite_url+)
      def ssh_shell_params
        ['-T', '-o', 'BatchMode=yes', '-p', gitolite_server_port, '-i', gitolite_ssh_private_key, gitolite_url]
      end

    end

  end
end
