require 'digest/md5'

module RedmineGitHosting::Commands

  module Sudo

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    ##########################
    #                        #
    #   SUDO Shell Wrapper   #
    #                        #
    ##########################

    module ClassMethods

      # Returns the sudo prefix to all sudo_* commands
      #
      # These are as follows:
      # * (-i) login as `gitolite_user` (setting ENV['HOME')
      # * (-n) non-interactive
      # * (-u `gitolite_user`) target user
      def sudo_shell_params
        ['-n', '-u', RedmineGitHosting::Config.gitolite_user, '-i']
      end


      # Execute a command as the gitolite user defined in +GitoliteWrapper.gitolite_user+.
      #
      # Will shell out to +sudo -n -u <gitolite_user> params+
      #
      def sudo_shell(*params)
        RedmineGitHosting::Utils.execute('sudo', sudo_shell_params.concat(params))
      end


      # Return only the output of the shell command
      # Throws an exception if the shell command does not exit with code 0.
      def sudo_capture(*params)
        RedmineGitHosting::Utils.capture('sudo', sudo_shell_params.concat(params))
      end


      def sudo_pipe_data(stdin)
        RedmineGitHosting::Utils.capture('sudo', sudo_shell_params.push('sh'), {stdin_data: stdin, binmode: true})
      end


      # Pipe file content via sudo to dest_file.
      # Expect file content to end with EOL (\n)
      def sudo_install_file(content, dest_file, filemode)
        stdin = [ 'cat', '<<\EOF', '>' + dest_file, "\n" + content.to_s + "EOF" ].join(' ')

        begin
          sudo_pipe_data(stdin)
          sudo_chmod(filemode, dest_file)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error(e.output)
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


      # Test properties of a path from the git user.
      #
      # e.g., Test if a directory exists: sudo_test('~/somedir', '-d')
      def sudo_test(path, testarg)
        out, _ , code = sudo_shell('eval', 'test', testarg, path)
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
        sudo_shell('eval', 'mkdir', *args)
      end


      # Syntaxic sugar for 'mkdir -p'
      def sudo_mkdir_p(path)
        sudo_mkdir('-p', path)
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


      # Syntaxic sugar for 'rm -rf' command
      #
      def sudo_rm_rf(path)
        sudo_rmdir(path, true)
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
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          empty_repo = false
        else
          logger.debug("Counted objects in repository directory '#{path}' : '#{output}'")

          if output.to_i == 0
            empty_repo = true
          else
            empty_repo = false
          end
        end

        return empty_repo
      end


      def sudo_get_dir_size(directory)
        sudo_capture('du', '-sh', directory).split(' ')[0] rescue ''
      end


      # Test if file content has changed
      #
      def sudo_file_changed?(source_file, dest_file)
        hash_content(local_content(source_file)) != hash_content(distant_content(dest_file))
      end


      private


        def hash_content(content)
          Digest::MD5.hexdigest(content)
        end


        def local_content(source_file)
          File.read(source_file)
        end


        def distant_content(destination_path)
          sudo_capture('cat', destination_path) rescue ''
        end

    end

  end
end
