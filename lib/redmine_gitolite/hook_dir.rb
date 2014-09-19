module RedmineGitolite

  class HookDir

    attr_reader :name
    attr_reader :destination_path


    def initialize(name, destination_path)
      @name             = name
      @destination_path = destination_path
    end


    def installed?
      if !exists?
        logger.info { "Global hook directory '#{name}' not created yet, installing it..." }

        if install_hooks_dir
          logger.info { "Global hook directory '#{name}' installed" }
        end
      end
      return exists?
    end


    private


      def logger
        RedmineGitolite::Log.get_logger(:global)
      end


      def exists?
        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "test -r '#{destination_path}' && echo 'yes' || echo 'no'").match(/yes/) ? true : false
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          return false
        end
      end


      def install_hooks_dir
        logger.info { "Installing hook directory '#{destination_path}'" }

        begin
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "mkdir -p '#{destination_path}'")
          RedmineGitolite::GitHosting.execute_command(:shell_cmd, "chmod 755 '#{destination_path}'")
          return true
        rescue => e
          logger.error { "Problems installing hook directory '#{destination_path}'" }
          return false
        end
      end

  end
end
