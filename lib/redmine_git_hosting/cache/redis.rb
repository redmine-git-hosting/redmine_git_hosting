require 'redis'
require 'digest/sha1'

module RedmineGitHosting
  module Cache
    class Redis < AbstractCache
      class << self

        def set_cache(repo_id, command, output)
          logger.debug("Redis Adapter : inserting cache entry for repository '#{repo_id}'")

          # Create a SHA256 of the Git command as key id
          hashed_command = hash_key(repo_id, command)

          # If *max_cache_time* is set to -1 (until next commit) then
          # set the cache time to 1 day (we don't know when will be the next commit)
          cache_time = (max_cache_time < 0) ? 86_400 : max_cache_time

          begin
            client.set(hashed_command, output, ex: cache_time)
            true
          rescue => e
            logger.error("Redis Adapter : could not insert in cache, this is the error : '#{e.message}'")
            false
          end
        end


        def get_cache(repo_id, command)
          logger.debug("Redis Adapter : getting cache entry for repository '#{repo_id}'")
          client.get(hash_key(repo_id, command))
        end


        def flush_cache!
          deleted = 0
          client.scan_each(match: all_entries) do |key|
            client.del(key)
            deleted += 1
          end
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
          client.scan_each(match: all_entries_for_repo(repo_id)) do |key|
            client.del(key)
            deleted += 1
          end
          logger.info("Redis Adapter : removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
        end


        # Return true.
        #
        def apply_cache_limit
          true
        end


        private


          def redis_namespace
            'git_hosting_cache'
          end


          def all_entries
            "#{redis_namespace}:*"
          end


          def all_entries_for_repo(repo_id)
            "#{redis_namespace}:#{digest(repo_id)}:*"
          end


          # Prefix each key with *git_hosting_cache:* to store them in a subdirectory.
          # When flushing cache, get all keys with this prefix and delete them.
          # Make SHA256 of the Git command as identifier
          #
          def hash_key(repo_id, command)
            "#{redis_namespace}:#{digest(repo_id)}:#{digest(command)}"
          end


          def digest(string)
            Digest::SHA256.hexdigest(string)[0..16]
          end


          def client
            @client ||= ::Redis.new(redis_options)
          end


          # Specify the Redis DB.
          # However, I don't know exactly how it's used by Redis...
          #
          def redis_options
            { db: redis_namespace, driver: :hiredis }
          end

      end
    end
  end
end
