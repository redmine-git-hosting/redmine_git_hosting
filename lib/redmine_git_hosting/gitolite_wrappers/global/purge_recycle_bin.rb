module RedmineGitHosting
  module GitoliteWrappers
    module Global
      class PurgeRecycleBin < GitoliteWrappers::Base

        def call
          RedmineGitHosting::RecycleBin.delete_expired_content
          RedmineGitHosting.logger.info('purge_recycle_bin : done !')
        end

      end
    end
  end
end
