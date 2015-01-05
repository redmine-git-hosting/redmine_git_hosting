module RedmineGitHosting::Plugins::Sweepers
  class RepositoryDeletor < BaseSweeper

    def post_delete
      # Delete hook param if needed
      move_repository_to_recycle if delete_repository?
      remove_git_cache
    end


    private


      def move_repository_to_recycle
        if repository_data.is_a?(Hash)
          RedmineGitHosting::Recycle.move_repository_to_recycle(repository_data)
        elsif repository_data.is_a?(Array)
          repository_data.each do |repo|
            RedmineGitHosting::Recycle.move_repository_to_recycle(repo)
          end
        end
      end


      def remove_git_cache
        logger.info("Clean cache for repository '#{gitolite_repo_name}'")
        RedmineGitHosting::Cache.clear_cache_for_repository(git_cache_id)
      end

  end
end
