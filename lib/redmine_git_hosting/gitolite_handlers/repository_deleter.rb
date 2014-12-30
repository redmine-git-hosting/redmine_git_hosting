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
        if repo_conf
          delete_repository
        else
          logger.warn("#{action} : repository '#{repo_name}' does not exist in Gitolite, exit !")
        end
      end


      private


        def logger
          RedmineGitHosting.logger
        end


        def delete_repository
          logger.info("#{action} : repository '#{repo_name}' exists in Gitolite, delete it ...")
          gitolite_config.rm_repo(repo_name)
        end

    end
  end
end
