module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryAdder < RepositoryHandler

      attr_reader :force


      def initialize(*args)
        super
        @force     = opts.delete(:force){ false }
        @old_perms = opts.delete(:old_perms){ {} }
      end


      def call
        if !configuration_exists?
          logger.info("#{action} : repository '#{gitolite_repo_name}' does not exist in Gitolite, create it ...")
          add_repository
        elsif configuration_exists? && force
          logger.warn("#{action} : repository '#{gitolite_repo_name}' already exists in Gitolite, force mode !")
          add_repository(true)
        else
          logger.warn("#{action} : repository '#{gitolite_repo_name}' already exists in Gitolite, exit !")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")
        end
      end


      private


        def add_repository(force = false)
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")

          if force
            # Recreate repository in Gitolite
            recreate_repository_config
          else
            # Create repository in Gitolite
            create_repository_config
          end
        end

    end
  end
end
