module RedmineGitHosting
  module RecycleBin
    class Manager

      attr_reader :recycle_bin_dir


      def initialize(recycle_bin_dir)
        @recycle_bin_dir = recycle_bin_dir
        create_recycle_bin_directory
      end


      def content
        begin
          load_recycle_bin_content(get_recycle_bin_content)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          []
        end
      end


      def delete_expired_content(expiration_time)
        begin
          expired_content = load_recycle_bin_content(get_expired_content(expiration_time))
          logger.info("Removing #{expired_content.length} expired objects from Recycle Bin :")
          expired_content.map(&:destroy!)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          []
        end
      end


      def delete_content(content_list = [])
        load_recycle_bin_content(content_list).map(&:destroy!)
      end


      def move_object_to_recycle(object_name, source_path)
        RedmineGitHosting::RecycleBin::DeletableItem.new(recycle_bin_dir, object_name).move!(source_path)
      end


      def restore_object_from_recycle(object_name, target_path)
        RedmineGitHosting::RecycleBin::RestorableItem.new(recycle_bin_dir, object_name).restore!(target_path)
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def load_recycle_bin_content(content_list = [])
          content_list.map { |dir| RedmineGitHosting::RecycleBin::Item.new(dir) }
        end


        def get_recycle_bin_content
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-prune', '-print').chomp.split("\n")
        end


        def get_expired_content(expiration_time)
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', '.*\.git', '-cmin', "+#{expiration_time}", '-prune', '-print').chomp.split("\n")
        end


        def create_recycle_bin_directory
          begin
            RedmineGitHosting::Commands.sudo_mkdir_p(recycle_bin_dir)
            RedmineGitHosting::Commands.sudo_chmod('770', recycle_bin_dir)
            true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Attempt to create recycle bin directory '#{recycle_bin_dir}' failed !")
            false
          end
        end

    end
  end
end
