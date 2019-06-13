module RedmineGitHosting
  module Cache
    extend self

    # Used in ShellRedirector but define here to keep a clean interface.
    #
    def max_cache_size
      RedmineGitHosting::Config.gitolite_cache_max_size
    end

    def set_cache(repo_id, out_value, primary_key, secondary_key = nil)
      return if out_value.strip.empty?

      command = compose_key(primary_key, secondary_key)
      adapter.apply_cache_limit if adapter.set_cache(repo_id, command, out_value)
    end

    def get_cache(repo_id, primary_key, secondary_key = nil)
      command = compose_key(primary_key, secondary_key)
      cached  = adapter.get_cache(repo_id, command)
      # Return result as a string stream
      cached.nil? ? nil : StringIO.new(cached)
    end

    def flush_cache!
      adapter.flush_cache!
    end

    # After resetting cache timing parameters -- delete entries that no-longer match
    def clear_obsolete_cache_entries
      adapter.clear_obsolete_cache_entries
    end

    # Clear the cache entries for given repository / git_cache_id
    def clear_cache_for_repository(repo_id)
      adapter.clear_cache_for_repository(repo_id)
    end

    def adapter
      case RedmineGitHosting::Config.gitolite_cache_adapter
      when 'database'
        Database
      when 'memcached'
        Memcached
      when 'redis'
        Redis
      else
        Database
      end
    end

    private

    def compose_key(key1, key2)
      if key2&.present?
        key1 + "\n" + key2
      else
        key1
      end
    end
  end
end
