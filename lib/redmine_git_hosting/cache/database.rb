module RedmineGitHosting
  module Cache
    class Database < AbstractCache
      class << self
        def set_cache(repo_id, command, output)
          logger.debug("DB Adapter : inserting cache entry for repository '#{repo_id}'")
          begin
            GitCache.create(command: command, command_output: output, repo_identifier: repo_id)
            true
          rescue => e
            logger.error("DB Adapter : could not insert in cache, this is the error : '#{e.message}'")
            false
          end
        end

        def get_cache(repo_id, command)
          cached = GitCache.find_by_repo_identifier_and_command(repo_id, command)
          if cached
            if valid_cache_entry?(cached.created_at)
              # Update updated_at flag
              cached.touch unless cached.command_output.nil?
              out = cached.command_output
            else
              cached.destroy
              out = nil
            end
          else
            out = nil
          end
          out
        end

        def flush_cache!
          ActiveRecord::Base.connection.execute('TRUNCATE git_caches')
        end

        def clear_obsolete_cache_entries
          return if time_limit.nil?

          deleted = GitCache.where('created_at < ?', time_limit).delete_all
          logger.info("DB Adapter : removed '#{deleted}' expired cache entries among all repositories")
        end

        def clear_cache_for_repository(repo_id)
          deleted = GitCache.where(repo_identifier: repo_id).delete_all
          logger.info("DB Adapter : removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
        end

        def apply_cache_limit
          GitCache.find(:last, order: 'created_at DESC').destroy if max_cache_elements >= 0 && GitCache.count > max_cache_elements
        end
      end
    end
  end
end
