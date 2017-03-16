require 'digest/md5'

module RedmineGitHosting
  module Commands
    module Sudo
      extend self

      ##########################
      #                        #
      #   SUDO Shell Wrapper   #
      #                        #
      ##########################


      # Pipe file content via sudo to dest_file.
      # Expect file content to end with EOL (\n)
      #
      def sudo_install_file(content, dest_file, filemode)
        stdin = [ 'cat', '<<\EOF', '>' + dest_file, "\n" + content.to_s + "EOF" ].join(' ')

        begin
          sudo_pipe_data(stdin)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error(e.output)
          return false
        else
          begin
            sudo_chmod(filemode, dest_file)
            return true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error(e.output)
            return false
          end
        end
      end


      # Test if a file exists with size > 0
      #
      def sudo_file_exists?(filename)
        sudo_test(filename, '-s')
      end


      # Test if a directory exists
      #
      def sudo_dir_exists?(dirname)
        sudo_test(dirname, '-r')
      end


      # Test properties of a path from the git user.
      #
      # e.g., Test if a directory exists: sudo_test('~/somedir', '-d')
      #
      def sudo_test(path, testarg)
        _, _ , code = sudo_shell('test', testarg, path)
        return code == 0
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        logger.debug("File check for #{path} failed : #{e.message}")
        false
      end


      # Calls mkdir with the given arguments on the git user's side.
      #
      # e.g., sudo_mkdir('-p', '/some/path')
      #
      def sudo_mkdir(*args)
        sudo_shell('mkdir', *args)
      end


      # Syntaxic sugar for 'mkdir -p'
      #
      def sudo_mkdir_p(path)
        sudo_mkdir('-p', path)
      end


      # Calls chmod with the given arguments on the git user's side.
      #
      # e.g., sudo_chmod('755', '/some/path')
      #
      def sudo_chmod(mode, file)
        sudo_shell('chmod', mode, file)
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
          sudo_shell('rm', '-rf', path)
        else
          sudo_shell('rmdir', path)
        end
      end


      # Syntaxic sugar for 'rm -rf' command
      #
      def sudo_rm_rf(path)
        sudo_rmdir(path, true)
      end


      # Moves a file/directory to a new target.
      #
      def sudo_move(old_path, new_path)
        sudo_shell('mv', old_path, new_path)
      end


      def sudo_get_dir_size(directory)
        sudo_capture('du', '-sh', directory).split(' ')[0] rescue ''
      end


      def sudo_cat(file)
        sudo_capture('cat', file) rescue ''
      end


      # Test if file content has changed
      #
      def sudo_file_changed?(source_file, dest_file)
        hash_content(content_from_redmine_side(source_file)) != hash_content(content_from_gitolite_side(dest_file))
      end


      # Test if file permissions has changed
      #
      def sudo_file_perms_changed?(filemode, dest_file)
        current_mode = sudo_capture('stat', '-c', "%a", dest_file)
        current_mode.chomp != filemode
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        logger.error(e.output)
        false
      end


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
        capture(cmd, { stdin_data: stdin, binmode: true })
      end


      private


        # Return the Sudo command with basic args.
        #
        def sudo
          if RedmineGitHosting::Config.gitolite_use_sudo?
            ['sudo', *sudo_shell_params]
          else
            []
          end
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


        # Return a md5 hash of the string passed.
        #
        def hash_content(content)
          Digest::MD5.hexdigest(content)
        end


        # Return the content of a local (Redmine side) file.
        #
        def content_from_redmine_side(file)
          File.read(file)
        rescue Errno::ENOENT => e
          logger.error(e.message)
          ''
        end


        # Return the content of a file on Gitolite side.
        #
        def content_from_gitolite_side(destination_path)
          sudo_cat(destination_path)
        end

    end
  end
end
