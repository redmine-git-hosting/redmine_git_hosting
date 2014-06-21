module RedmineGitolite

  module GitoliteWrapper

    class Admin

      def initialize(action, object_id, options = {})
        @admin = RedmineGitolite::GitoliteWrapper.admin
        @gitolite_config = @admin.config

        @action    = action
        @object_id = object_id
        @options   = options
      end


      def purge_recycle_bin
        repositories_array = @object_id
        recycle = RedmineGitolite::Recycle.new
        recycle.delete_expired_files(repositories_array)
        logger.info { "#{@action} : done !" }
      end


      private


      def logger
        RedmineGitolite::Log.get_logger(:worker)
      end


      def gitolite_admin_repo_commit(message = '')
        logger.info { "#{@action} : commiting to Gitolite..." }
        @admin.save("#{@action} : #{message}")
      rescue => e
        logger.error { "#{e.message}" }
      end

    end
  end
end
