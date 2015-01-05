require 'redis'
require 'digest/sha1'

module RedmineGitHosting::Cache
  class Redis < AbstractCache

    def set_cache(command, output, repo_id)
      logger.debug("Redis Adapter : inserting cache entry for repository '#{repo_id}'")

      # Create a SHA256 of the Git command as key id
      hashed_command = hash_key(command)

      begin
        create_or_update_repo_references(repo_id, hashed_command)
        client.set(hashed_command, output, ex: max_cache_time)
        true
      rescue => e
        logger.error("Redis Adapter : could not insert in cache, this is the error : '#{e.message}'")
        false
      end
    end


    def get_cache(command)
      client.get(hash_key(command))
    end


    def flush_cache!
      client.scan_each(match: 'git_hosting_cache_*') { |key| client.del(key) }
    end


    # Return true, this is done automatically by Redis with the
    # *max_cache_time* params (see above)
    #
    def clear_obsolete_cache_entries
      true
    end


    def clear_cache_for_repository(repo_id)
      # Create a SHA256 of the repo_id as key id
      hashed_repo_id = hash_key(repo_id)
      # Find repository references in Redis
      repo_references = client.get(hashed_repo_id)
      return true if repo_references.nil?
      # Delete reference keys
      repo_references = repo_references.split(',').select { |r| !r.empty? }
      repo_references.map { |key| client.del(key) }
      logger.info("Redis Adapter : removed '#{repo_references.size}' expired cache entries for repository '#{repo_id}'")
      # Reset references count
      client.set(hashed_repo_id, '', ex: max_cache_time)
    end


    # Return true.
    #
    def apply_cache_limit
      true
    end


    private


      def create_or_update_repo_references(repo_id, reference)
        # Create a SHA256 of the repo_id as key id
        hashed_repo_id = hash_key(repo_id)
        # Find it in Redis
        repo_references = client.get(hashed_repo_id)
        if repo_references.nil?
          client.set(hashed_repo_id, reference, ex: max_cache_time)
        else
          client.append(hashed_repo_id, ',' + reference)
        end
      end


      # Prefix each key with *git_hosting_cache_* because keys
      # are stored in the Redis root namespace.
      # When flushing cache, get all keys with this prefix and delete them.
      #
      def hash_key(key)
        'git_hosting_cache_' + Digest::SHA256.hexdigest(key)
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
