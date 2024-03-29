# frozen_string_literal: true

module RedmineGitHosting
  module RecycleBin
    class DeletableItem
      include RecycleBin::ItemBase

      def move!(source_path)
        if directory_exists? source_path
          logger.info "Moving '#{object_name}' to Recycle Bin..."
          logger.debug "'#{source_path}' => '#{target_path}'"
          do_move source_path
        else
          logger.warn "Source directory does not exist '#{source_path}', exiting!"
          false
        end
      end

      def target_path
        @target_path ||= File.join recycle_bin_dir, "#{Time.now.to_i}#{TRASH_DIR_SEP}#{trash_name}.git"
      end

      private

      def do_move(source_path)
        RedmineGitHosting::Commands.sudo_move source_path, target_path
        logger.info 'Done !'
        true
      rescue RedmineGitHosting::Error::GitoliteCommandException
        logger.error "Attempt to move '#{source_path}' to Recycle Bin failed!"
        false
      end
    end
  end
end
