module RedmineGitHosting
  module RecycleBin
    class RestorableItem

      include RecycleBin::ItemBase


      def restore!(target_path)
        if trashed_object.nil?
          logger.warn("No matching item found for '#{object_name}' in Recycle Bin, exiting !")
          false
        else
          logger.info("Restoring '#{object_name}' from Recycle Bin...")
          logger.debug("'#{trashed_object}' => '#{target_path}'")
          create_parent_dir(target_path) && do_restore(target_path)
        end
      end


      def source_path
        File.join(recycle_bin_dir, "[0-9]+#{TRASH_DIR_SEP}#{trash_name}.git")
      end


      # Pull up any matching repositories. Sort them (beginning is representation of time)
      #
      def trashed_objects
        begin
          find_trashed_object(source_path)
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          []
        end
      end


      def trashed_object
        trashed_objects.first
      end


      private


        def create_parent_dir(target_path)
          begin
            logger.info("Creating parent dir : '#{File.dirname(target_path)}'")
            RedmineGitHosting::Commands.sudo_mkdir_p(File.dirname(target_path))
            true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Attempt to create parent dir for '#{trashed_object}' failed !")
            false
          end
        end


        def do_restore(target_path)
          begin
            RedmineGitHosting::Commands.sudo_move(trashed_object, target_path)
            logger.info('Done !')
            true
          rescue RedmineGitHosting::Error::GitoliteCommandException => e
            logger.error("Attempt to recover '#{trashed_object}' from Recycle Bin failed !")
            false
          end
        end

    end
  end
end
