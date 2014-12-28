module RedmineGitHosting
  module GitoliteWrapper
    class Repositories < Admin

      attr_reader :create_readme_file


      def initialize(*args)
        super
        @create_readme_file = options.delete(:create_readme_file){ false }
        # Find object or raise error
        # find_repository
      end


      def add_repository
        if repository = Repository.find_by_id(object_id)
          admin.transaction do
            RedmineGitHosting::GitoliteHandlers::RepositoryAdder.new(repository, gitolite_config, action, options).call
            gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")
            recycle = RedmineGitHosting::Recycle.new
            @recovered = recycle.recover_repository_if_present?(repository)

            if !@recovered
              logger.info("#{action} : let Gitolite create empty repository '#{repository.gitolite_repository_path}'")
            else
              logger.info("#{action} : restored existing Gitolite repository '#{repository.gitolite_repository_path}' for update")
            end
          end

          # Create README file if asked and not already recovered
          RedmineGitHosting::GitoliteHandlers::RepositoryReadmeCreator.new(repository).call if create_readme_file? && !@recovered

          # Fetch changeset
          repository.fetch_changesets
        else
          logger.error("#{action} : repository does not exist anymore, object is nil, exit !")
        end
      end


      def update_repository
        if repository = Repository.find_by_id(object_id)
          admin.transaction do
            RedmineGitHosting::GitoliteHandlers::RepositoryUpdater.new(repository, gitolite_config, action, options).call
            gitolite_admin_repo_commit("#{repository.gitolite_repository_name}")
          end
        else
          logger.error("#{action} : repository does not exist anymore, object is nil, exit !")
        end
      end


      def delete_repositories
        admin.transaction do
          object_id.each do |repository_data|
            RedmineGitHosting::GitoliteHandlers::RepositoryDeleter.new(repository_data, gitolite_config, action).call
            gitolite_admin_repo_commit("#{repository_data['repo_name']}")
          end
        end
      end


      def update_repository_default_branch
        if repository = Repository.find_by_id(object_id)
          RedmineGitHosting::GitoliteHandlers::RepositoryBranchUpdater.new(repository).call
        else
          logger.error("#{action} : repository does not exist anymore, object is nil, exit !")
        end
      end


      private


        def create_readme_file?
          create_readme_file == true || create_readme_file == 'true'
        end

    end
  end
end
