module GitoliteWrappers
  module Global
    class PurgeRecycleBin < GitoliteWrappers::Base
      unloadable

      def call
        RedmineGitHosting::RecycleBin.delete_content(object_id)
        RedmineGitHosting.logger.info('purge_recycle_bin : done !')
      end

    end
  end
end
