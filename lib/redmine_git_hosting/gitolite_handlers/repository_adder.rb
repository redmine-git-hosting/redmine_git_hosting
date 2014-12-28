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
          add_repository
        elsif configuration_exists? && force
          add_repository_forced
        else
          logger.warn("#{action} : repository '#{gitolite_repo_name}' already exists in Gitolite, exit !")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")
        end
      end


      private


        def add_repository
          logger.info("#{action} : repository '#{gitolite_repo_name}' does not exist in Gitolite, create it ...")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")

          # Create repository in Gitolite
          create_repository_config
        end


        def add_repository_forced
          logger.warn("#{action} : repository '#{gitolite_repo_name}' already exists in Gitolite, force mode !")
          logger.debug("#{action} : repository path '#{gitolite_repo_path}'")

          # Recreate repository in Gitolite
          recreate_repository_config
        end

    end
  end
end
