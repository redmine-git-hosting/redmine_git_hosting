module RedmineGitHosting::HookManager

  class HookDir

    attr_reader :name
    attr_reader :destination_path


    def initialize(name, destination_path)
      @name             = name
      @destination_path = destination_path
    end


    def installed?
      if !exists?
        logger.info("Global hook directory '#{name}' not created yet, installing it...")

        if install_hooks_dir
          logger.info("Global hook directory '#{name}' installed")
        end
      end
      return exists?
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def exists?
        RedmineGitHosting::Commands.sudo_dir_exists?(destination_path)
      end


      def install_hooks_dir
        logger.info("Installing hook directory '#{destination_path}'")

        begin
          RedmineGitHosting::Commands.sudo_mkdir_p(destination_path)
          RedmineGitHosting::Commands.sudo_chmod('755', destination_path)
          return true
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Problems installing hook directory '#{destination_path}'")
          logger.error(e.output)
          return false
        end
      end

  end
end
