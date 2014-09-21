module RedmineGitolite
  module GitoliteWrapper

    class Admin

      attr_reader :admin
      attr_reader :gitolite_config

      attr_reader :action
      attr_reader :object_id
      attr_reader :options


      def initialize(admin, action, object_id, options = {})
        @admin           = admin
        @gitolite_config = @admin.config

        @action    = action
        @object_id = object_id
        @options   = options
      end


      def purge_recycle_bin
        RedmineGitolite::Recycle.new().delete_expired_files(object_id)
        logger.info { "#{action} : done !" }
      end


      def flush_settings_cache
        logger.info { "Settings cache flushed!" }
      end


      private


        def logger
          RedmineGitolite::Log.get_logger(:worker)
        end


        def gitolite_admin_repo_commit(message = '')
          logger.info { "#{action} : commiting to Gitolite..." }
          admin.save("#{action} : #{message}")
        rescue => e
          logger.error { "#{e.message}" }
        end

    end

  end
end
