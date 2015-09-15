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
          RedmineGitHosting::RecycleBin.move_object_to_recycle(repository_data[:repo_name], repository_data[:repo_path])
        elsif repository_data.is_a?(Array)
          repository_data.each do |object_data|
            RedmineGitHosting::RecycleBin.move_object_to_recycle(object_data[:repo_name], object_data[:repo_path])
          end
        end
      end


      def remove_git_cache
        logger.info("Clean cache for repository '#{gitolite_repo_name}'")
        RedmineGitHosting::Cache.clear_cache_for_repository(git_cache_id)
      end

  end
end
