module RedmineGitHosting
  module RecycleBin
    class Item

      attr_reader :path


      def initialize(path)
        @path = path
      end


      def size
        RedmineGitHosting::Commands.sudo_get_dir_size(path)
      end


      def destroy!
        logger.info("Deleting '#{path}' from Recycle Bin")
        begin
          RedmineGitHosting::Commands.sudo_rmdir(path, true)
          logger.info('Done !')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Errors while deleting '#{path}' from Recycle Bin !")
        end
      end


      private


        def logger
          RedmineGitHosting.logger
        end

    end
  end
end
