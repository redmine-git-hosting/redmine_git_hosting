module RedmineGitHosting::Cache
  class Database < AbstractCache

    def set_cache(command, output, repo_id)
      logger.debug("Inserting cache entry for repository '#{repo_id}'")
      begin
        GitCache.create(
          command:         command,
          command_output:  output,
          repo_identifier: repo_id
        )
        true
      rescue => e
        logger.error("Could not insert in cache, this is the error : '#{e.message}'")
        false
      end
    end


    def get_cache(command)
      GitCache.find_by_command(command)
    end


    def clear_obsolete_cache_entries(limit)
      deleted = GitCache.delete_all(['created_at < ?', limit])
      logger.info("Removed '#{deleted}' expired cache entries among all repositories")
    end


    def clear_cache_for_repository(repo_id)
      deleted = GitCache.delete_all(['repo_identifier = ?', repo_id])
      logger.info("Removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
    end


    def apply_cache_limit(max_cache_elements)
      GitCache.find(:last, order: 'created_at DESC').destroy if max_cache_elements >= 0 && GitCache.count > max_cache_elements
    end

  end
end
