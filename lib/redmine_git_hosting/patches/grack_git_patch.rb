require 'grack/git'

module RedmineGitHosting
  module Patches
    module GrackGitPatch

      def initialize(git_path, repo_path, user)
        @user = user
        super(git_path, repo_path)
      end


      # Override original *valid_repo?* method to test directory presence with Sudo
      def valid_repo?
        directory_exists?(repo)
      end


      # Override original *command* method to prefix the command with Sudo and other args.
      #
      def command(cmd)
        git_command_with_sudo(cmd)
      end


      # Override original *capture* method because the original IO.popen().read let zombie process behind.
      # This method is called :
      #  * to get repository Git config (http.uploadpack || http.receivepack)
      #  * to get repository info refs :
      #    0087deab8f3d612a47e7e153ed21bbc52a480205035a refs/heads/devel report-status delete-refs side-band-64k quiet ofs-delta agent=git/1.9.1
      #  * to get repository refs :
      #    003f91a7b1dad21020e96d52119c585881c02f2fae45 refs/heads/master

      # Note : *service_rpc* also calls IO.popen but pass a block !.
      # Passing a block to IO.popen auto-close the pipe/thread.

      def capture(command)
        # Extract Args
        cmd  = command.shift
        args = command

        begin
          RedmineGitHosting::Utils::Exec.capture(cmd, args)
        rescue => e
          logger.error('Problems while getting SmartHttp params')
          # Return empty string since the next method will call *chomp* on it
          ''
        end
      end


      # Override original *popen_options* method.
      # The original one try to chdir before executing the command by
      # passing 'chdir: @dir' option to IO.popen.
      # This is wrong as we can't chdir to Gitolite directory.
      # Notes : this method is called in *service_rpc* (not overriden)
      #
      def popen_options
        { unsetenv_others: true }
      end


      # Override original *popen_env* method.
      # The original one passes useless arg (GL_ID) to IO.popen.
      # Notes : this method is called in *service_rpc* (not overriden)
      #
      def popen_env
         { 'PATH' => ENV['PATH'] }
      end


      private


        def directory_exists?(dir)
          RedmineGitHosting::Commands.sudo_dir_exists?(dir)
        end


        # We sometimes need to add *--git-dir* arg to Git command otherwise
        # Git looks for the repository in the current path.
        def git_command_with_sudo(params)
          if command_require_chdir?(params.last)
            git_command_with_chdir.concat(params)
          else
            git_command_without_chdir.concat(params)
          end
        end


        def command_require_chdir?(cmd)
          cmd == 'update-server-info' || cmd == 'http.receivepack'  || cmd == 'http.uploadpack' || cmd == 'rev-parse'
        end


        def git_command_without_chdir
          RedmineGitHosting::Commands.sudo_git_cmd(smart_http_args)
        end


        def git_command_with_chdir
          RedmineGitHosting::Commands.sudo_git_args_for_repo(@repo, smart_http_args)
        end


        def smart_http_args
          [
            'env',
            "GL_BINDIR=#{RedmineGitHosting::Config.gitolite_bin_dir}",
            "GL_LIBDIR=#{RedmineGitHosting::Config.gitolite_lib_dir}",
            "GL_REPO=#{repository_object.gitolite_repository_name}",
            "GL_USER=#{@user}"
          ]
        end


        def logger
          RedmineGitHosting.logger
        end


        def repository_object
          @repository_object ||= Repository::Xitolite.find_by_path(@repo, loose: true)
        end

    end
  end
end

unless Grack::Git.included_modules.include?(RedmineGitHosting::Patches::GrackGitPatch)
  Grack::Git.send(:prepend, RedmineGitHosting::Patches::GrackGitPatch)
end
