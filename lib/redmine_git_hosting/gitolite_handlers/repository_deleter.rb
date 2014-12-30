module RedmineGitHosting
  module GitoliteHandlers
    class RepositoryDeleter

      attr_reader :repository_data
      attr_reader :repo_name
      attr_reader :repo_path
      attr_reader :repo_conf
      attr_reader :gitolite_config
      attr_reader :action


      def initialize(repository_data, gitolite_config, action)
        @repository_data = repository_data
        @repo_name       = repository_data['repo_name']
        @repo_path       = repository_data['repo_path']
        @repo_conf       = gitolite_config.repos[repo_name]
        @gitolite_config = gitolite_config
        @action          = action
      end


      def call
        handle_repository_delete
        move_repository_to_recycle
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def handle_repository_delete
          if !repo_conf
            logger.warn("#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !")
            logger.debug("#{action} : repository path '#{repo_path}'")
            return false
          else
            logger.info("#{action} : repository '#{repo_name}' exists in Gitolite, delete it ...")
            logger.debug("#{action} : repository path '#{repo_path}'")
            gitolite_config.rm_repo(repo_name)
          end
        end


        def move_repository_to_recycle
          recycle = RedmineGitHosting::Recycle.new
          recycle.move_repository_to_recycle(repository_data) if RedmineGitHosting::Config.delete_git_repositories?
        end

    end
  end
end
