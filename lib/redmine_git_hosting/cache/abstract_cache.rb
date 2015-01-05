module RedmineGitHosting::Cache
  class AbstractCache

    def set_cache(command, output, repo_id)
      raise NotImplementedError
    end


    def get_cache(command)
      raise NotImplementedError
    end


    def clear_obsolete_cache_entries(limit)
      raise NotImplementedError
    end


    def clear_cache_for_repository(repo_id)
      raise NotImplementedError
    end


    def apply_cache_limit(max_cache_elements)
      raise NotImplementedError
    end


    private


      def logger
        RedmineGitHosting.logger
      end

  end
end
