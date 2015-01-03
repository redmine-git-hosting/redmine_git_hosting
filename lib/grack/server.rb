module Grack
  class Server

    # Override original *get_git_dir* method because the path is relative
    # and accessed via Sudo.
    def get_git_dir(path)
      path = gitolite_path(path)
      if !directory_exists?(path)
        false
      else
        path # TODO: check is a valid git directory
      end
    end


    # Override original *git_command* method to prefix the command with Sudo and other args.
    def git_command(params)
      git_command_with_sudo(params)
    end


    # Override original *capture* method to catch errors
    def capture(command)
      begin
        IO.popen(popen_env, command, popen_options).read
      rescue => e
        logger.error('Problems while getting SmartHttp params')
      end
    end


    # Override original *popen_options* method.
    # The original one try to chdir before executing the command by
    # passing 'chdir: @dir' option to IO.popen.
    # This is wrong as we can't chdir to Gitolite directory.
    def popen_options
      { unsetenv_others: true }
    end


    # Override original *popen_options* method.
    # The original one passes useless arg (GL_ID) to IO.popen.
    def popen_env
       { 'PATH' => ENV['PATH'] }
    end


    private


      def gitolite_path(path)
        File.join(RedmineGitHosting::Config.gitolite_global_storage_dir, RedmineGitHosting::Config.gitolite_redmine_storage_dir, path)
      end


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
        cmd == 'update-server-info' || cmd == 'http.receivepack'  || cmd == 'http.uploadpack'
      end


      def git_command_without_chdir
        RedmineGitHosting::Commands.sudo_git_cmd(smart_http_args)
      end


      def git_command_with_chdir
        RedmineGitHosting::Commands.sudo_git_args_for_repo(@dir, smart_http_args)
      end


      def smart_http_args
        ['env', 'GL_BYPASS_UPDATE_HOOK=true']
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
