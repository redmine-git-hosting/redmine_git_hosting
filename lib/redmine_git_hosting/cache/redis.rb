require 'redis'
require 'digest/sha1'

module RedmineGitHosting::Cache
  class Redis < AbstractCache

    def set_cache(repo_id, command, output)
      logger.debug("Redis Adapter : inserting cache entry for repository '#{repo_id}'")

      # Create a SHA256 of the Git command as key id
      hashed_command = hash_key(repo_id, command)

      begin
        client.set(hashed_command, output, ex: max_cache_time)
        true
      rescue => e
        logger.error("Redis Adapter : could not insert in cache, this is the error : '#{e.message}'")
        false
      end
    end


    def get_cache(repo_id, command)
      client.get(hash_key(repo_id, command))
    end


    def flush_cache!
      deleted = 0
      client.scan_each(match: 'git_hosting_cache:*') { |key|
        client.del(key)
        deleted += 1
      }
      logger.info("Redis Adapter : removed '#{deleted}' expired cache entries among all repositories")
    end


    # Return true, this is done automatically by Redis with the
    # *max_cache_time* params (see above)
    #
    def clear_obsolete_cache_entries
      true
    end


    def clear_cache_for_repository(repo_id)
      deleted = 0
      client.scan_each(match: "#{key_prefix(repo_id)}:*") { |key|
        client.del(key)
        deleted += 1
      }
      logger.info("Redis Adapter : removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
    end


    # Return true.
    #
    def apply_cache_limit
      true
    end


    private


      # Prefix each key with *git_hosting_cache:* to store them in a subdirectory.
      # When flushing cache, get all keys with this prefix and delete them.
      #
      def key_prefix(repo_id)
        "git_hosting_cache:#{repo_id}"
      end


      # Make SHAR256 of the Git command as identifier
      #
      def hash_key(repo_id, command)
        "#{key_prefix(repo_id)}:#{Digest::SHA256.hexdigest(command)}"
      end


      def client
        @client ||= ::Redis.new(redis_options)
      end


      # Specify the Redis DB.
      # However, I don't know exactly how it's used by Redis...
      #
      def redis_options
        { db: 'git_hosting_cache', driver: :hiredis }
      end

  end
end
