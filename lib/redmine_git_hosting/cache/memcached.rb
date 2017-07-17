require 'dalli'
require 'digest/sha1'

module RedmineGitHosting
  module Cache
    class Memcached < AbstractCache
      class << self

        def set_cache(repo_id, command, output)
          logger.debug("Memcached Adapter : inserting cache entry for repository '#{repo_id}'")

          # Create a SHA256 of the Git command as key id
          hashed_command = hash_key(command)

          begin
            create_or_update_repo_references(repo_id, hashed_command)
            client.set(hashed_command, output)
            true
          rescue => e
            logger.error("Memcached Adapter : could not insert in cache, this is the error : '#{e.message}'")
            false
          end
        end


        def get_cache(repo_id, command)
          client.get(hash_key(command))
        end


        def flush_cache!
          client.flush
        end


        # Return true, this is done automatically by Memcached with the
        # *max_cache_time* params (see below)
        #
        def clear_obsolete_cache_entries
          true
        end


        def clear_cache_for_repository(repo_id)
          # Create a SHA256 of the repo_id as key id
          hashed_repo_id = hash_key(repo_id)
          # Find repository references in Memcached
          repo_references = client.get(hashed_repo_id)
          return true if repo_references.nil?
          # Delete reference keys
          repo_references = repo_references.split(',').select { |r| !r.empty? }
          repo_references.map { |key| client.delete(key) }
          logger.info("Memcached Adapter : removed '#{repo_references.size}' expired cache entries for repository '#{repo_id}'")
          # Reset references count
          client.set(hashed_repo_id, '', max_cache_time, raw: true)
        end


        # Return true. If cache is full, Memcached drop the oldest objects to add new ones.
        #
        def apply_cache_limit
          true
        end


        private


          def create_or_update_repo_references(repo_id, reference)
            # Create a SHA256 of the repo_id as key id
            hashed_repo_id = hash_key(repo_id)
            # Find it in Memcached
            repo_references = client.get(hashed_repo_id)
            if repo_references.nil?
              client.set(hashed_repo_id, reference, max_cache_time, raw: true)
            else
              client.append(hashed_repo_id, ',' + reference)
            end
          end


          def hash_key(key)
            Digest::SHA256.hexdigest(key)
          end


          def client
            @client ||= Dalli::Client.new('localhost:11211', memcached_options)
          end


          def memcached_options
            { namespace: 'redmine_git_hosting', compress: true, expires_in: max_cache_time, value_max_bytes: max_cache_size }
          end

      end
    end
  end
end
