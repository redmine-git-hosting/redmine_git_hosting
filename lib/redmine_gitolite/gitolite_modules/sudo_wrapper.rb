module RedmineGitolite::GitoliteModules

  module SudoWrapper

    ##########################
    #                        #
    #   SUDO Shell Wrapper   #
    #                        #
    ##########################

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      # Returns the sudo prefix to all sudo_* commands
      #
      # These are as follows:
      # * (-i) login as `gitolite_user` (setting ENV['HOME')
      # * (-n) non-interactive
      # * (-u `gitolite_user`) target user
      def sudo_shell_params
        ['-n', '-u', gitolite_user, '-i']
      end


      # Execute a command as the gitolite user defined in +GitoliteWrapper.gitolite_user+.
      #
      # Will shell out to +sudo -n -u <gitolite_user> params+
      #
      def sudo_shell(*params)
        RedmineGitolite::GitHosting.execute('sudo', sudo_shell_params.concat(params))
      end


      # Return only the output of the shell command
      # Throws an exception if the shell command does not exit with code 0.
      def sudo_capture(*params)
        RedmineGitolite::GitHosting.capture('sudo', sudo_shell_params.concat(params))
      end


      def sudo_pipe_capture(*params, stdin)
        RedmineGitolite::GitHosting.capture('sudo', sudo_shell_params.concat(params), {stdin_data: stdin, binmode: true})
      end


      # Pipe file content via sudo to dest_file.
      # Expect file content to end with EOL (\n)
      def sudo_install_file(content, dest_file, filemode)
        stdin = [ 'cat', '<<\EOF', '>' + dest_file, "\n" + content.to_s + "EOF" ].join(' ')

        begin
          sudo_pipe_capture('sh', stdin)
          sudo_chmod(filemode, dest_file)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { e.output }
          return false
        end
      end


      # Test if a file exists with size > 0
      def sudo_file_exists?(filename)
        sudo_test(filename, '-s')
      end


      # Test if a directory exists
      def sudo_dir_exists?(dirname)
        sudo_test(dirname, '-r')
      end


      def sudo_update_gitolite!
        logger.info { "Running '#{gitolite_command.join(' ')}' on the Gitolite install ..." }
        begin
          sudo_shell(*gitolite_command)
          return true
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { e.output }
          return false
        end
      end


      # Test properties of a path from the git user.
      #
      # e.g., Test if a directory exists: sudo_test('~/somedir', '-d')
      def sudo_test(path, *testarg)
        out, _ , code = sudo_shell('eval', 'test', *testarg, path)
        return code == 0
      rescue => e
        logger.debug("File check for #{path} failed : #{e.message}")
        false
      end


      # Calls mkdir with the given arguments on the git user's side.
      #
      # e.g., sudo_mkdir('-p', '/some/path')
      #
      def sudo_mkdir(*args)
        sudo_shell('eval', 'mkdir', *args)
      end


      # Calls chmod with the given arguments on the git user's side.
      #
      # e.g., sudo_chmod('755', '/some/path')
      #
      def sudo_chmod(mode, file)
        sudo_shell('eval', 'chmod', mode, file)
      end


      # Removes a directory and all subdirectories below gitolite_user's $HOME.
      #
      # Assumes a relative path.
      #
      # If force=true, it will delete using 'rm -rf <path>', otherwise
      # it uses rmdir
      #
      def sudo_rmdir(path, force = false)
        if force
          sudo_shell('eval', 'rm', '-rf', path)
        else
          sudo_shell('eval', 'rmdir', path)
        end
      end


      # Moves a file/directory to a new target.
      #
      def sudo_move(old_path, new_path)
        sudo_shell('eval', 'mv', old_path, new_path)
      end


      # Test if repository is empty on Gitolite side
      #
      def sudo_repository_empty?(path)
        empty_repo = false

        path = File.join('$HOME', path, 'objects')

        begin
          output = sudo_capture('eval', 'find', path, '-type', 'f', '|', 'wc', '-l')
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          empty_repo = false
        else
          logger.debug { "Counted objects in repository directory '#{path}' : '#{output}'" }

          if output.to_i == 0
            empty_repo = true
          else
            empty_repo = false
          end
        end

        return empty_repo
      end


      ###############################
      ##                           ##
      ##        SUDO TESTS         ##
      ##                           ##
      ###############################

      ## SUDO TEST1
      def can_gitolite_sudo_to_redmine_user?
        logger.info { "Testing if Gitolite user '#{gitolite_user}' can sudo to Redmine user '#{redmine_user}'..." }

        if gitolite_user == redmine_user
          logger.info { "OK!" }
          return true
        end

        begin
          test = sudo_capture('sudo', '-n', '-u', redmine_user, '-i', 'whoami')
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.warn { "Error while testing can_gitolite_sudo_to_redmine_user" }
          return false
        else
          if test.match(/#{redmine_user}/)
            logger.info { "OK!" }
            return true
          else
            logger.warn { "Error while testing can_gitolite_sudo_to_redmine_user" }
            return false
          end
        end
      end


      ## SUDO TEST2
      def can_redmine_sudo_to_gitolite_user?
        logger.info { "Testing if Redmine user '#{redmine_user}' can sudo to Gitolite user '#{gitolite_user}'..." }

        if gitolite_user == redmine_user
          logger.info { "OK!" }
          return true
        end

        begin
          test = sudo_capture('whoami')
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while testing can_redmine_sudo_to_gitolite_user" }
          return false
        else
          if test.match(/#{gitolite_user}/)
            logger.info { "OK!" }
            return true
          else
            logger.warn { "Error while testing can_redmine_sudo_to_gitolite_user" }
            return false
          end
        end
      end

    end

  end
end
