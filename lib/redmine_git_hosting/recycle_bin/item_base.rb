module RedmineGitHosting
  module RecycleBin
    module ItemBase

      TRASH_DIR_SEP = '__'

      attr_reader :object_name
      attr_reader :recycle_bin_dir


      def initialize(recycle_bin_dir, object_name)
        @recycle_bin_dir = recycle_bin_dir
        @object_name     = object_name
      end


      def trash_name
        object_name.gsub(/\//, TRASH_DIR_SEP)
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def directory_exists?(dir)
          RedmineGitHosting::Commands.sudo_dir_exists?(dir)
        end


        def find_trashed_object(regex)
          RedmineGitHosting::Commands.sudo_capture('find', recycle_bin_dir, '-type', 'd', '-regex', regex, '-prune', '-print').chomp.split("\n").sort { |x, y| y <=> x }
        end

    end
  end
end
