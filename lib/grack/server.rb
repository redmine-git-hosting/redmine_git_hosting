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
      git_params.concat(params)
    end


    # Override original *capture* method to catch errors
    def capture(command)
      begin
        IO.popen(popen_env, command, popen_options).read
      rescue => e
        logger.error("Problems while getting SmartHttp params")
      end
    end


    # Override original *popen_options* method.
    # The original one try to chdir before executing the command by
    # passing 'chdir: @dir' option to IO.popen.
    # This is wrong as we can't chdir to Gitolite directory.
    def popen_options
      {}
    end


    # Override original *popen_options* method.
    # The original one passes (useless I think) args to IO.popen.
    def popen_env
      {}
    end


    private


      def gitolite_path(path)
        File.join(RedmineGitHosting::Config.gitolite_global_storage_dir, RedmineGitHosting::Config.gitolite_redmine_storage_dir, path)
      end


      def directory_exists?(dir)
        RedmineGitHosting::Commands.sudo_dir_exists?(dir)
      end


      def git_params
        [ 'sudo', *RedmineGitHosting::Commands.sudo_shell_params, 'env', 'GL_BYPASS_UPDATE_HOOK=true', 'git' ].clone
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
