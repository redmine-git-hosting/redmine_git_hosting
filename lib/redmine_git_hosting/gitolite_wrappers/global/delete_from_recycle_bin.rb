module RedmineGitHosting
  module GitoliteWrappers
    module Global
      class DeleteFromRecycleBin < GitoliteWrappers::Base

        def call
          RedmineGitHosting::RecycleBin.delete_content(object_id)
          RedmineGitHosting.logger.info('delete_from_recycle_bin : done !')
        end

      end
    end
  end
end
