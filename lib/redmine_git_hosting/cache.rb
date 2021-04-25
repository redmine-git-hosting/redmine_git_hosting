# frozen_string_literal: true

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

      command = compose_key primary_key, secondary_key
      adapter.apply_cache_limit if adapter.set_cache repo_id, command, out_value
    end

    def get_cache(repo_id, primary_key, secondary_key = nil)
      command = compose_key primary_key, secondary_key
      cached  = adapter.get_cache repo_id, command
      # Return result as a string stream
      cached.nil? ? nil : StringIO.new(cached)
    end

    delegate :flush_cache!, to: :adapter

    # After resetting cache timing parameters -- delete entries that no-longer match
    delegate :clear_obsolete_cache_entries, to: :adapter

    # Clear the cache entries for given repository / git_cache_id
    delegate :clear_cache_for_repository, to: :adapter

    def adapter
      case RedmineGitHosting::Config.gitolite_cache_adapter
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
        "#{key1}\n#{key2}"
      else
        key1
      end
    end
  end
end
