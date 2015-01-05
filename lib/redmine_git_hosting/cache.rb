module RedmineGitHosting
  module Cache

    class << self

      def max_cache_time
        RedmineGitHosting::Config.gitolite_cache_max_time
      end


      def max_cache_elements
        RedmineGitHosting::Config.gitolite_cache_max_elements
      end


      # Used in ShellRedirector but define here to keep a clean interface.
      def max_cache_size
        RedmineGitHosting::Config.gitolite_cache_max_size
      end


      def set_cache(repo_id, out_value, primary_key, secondary_key = nil)
        logger.debug("Inserting cache entry for repository '#{repo_id}'")
        logger.debug(compose_key(primary_key, secondary_key))
        command = compose_key(primary_key, secondary_key)
        set_cache_entry(command, out_value, repo_id)
      end


      def check_cache(primary_key, secondary_key = nil)
        cached = get_cache_entry(primary_key, secondary_key)

        if cached
          if valid_cache_entry?(cached)
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

        # Return result as a string stream
        out.nil? ? nil : StringIO.new(out)
      end


      # After resetting cache timing parameters -- delete entries that no-longer match
      def clear_obsolete_cache_entries
        return if max_cache_time < 0  # No expiration needed
        limit = Time.now - max_cache_time
        do_clear_obsolete_cache_entries(limit)
      end


      # Clear the cache entries for given repository / git_cache_id
      def clear_cache_for_repository(repo_id)
        do_clear_cache_for_repository(repo_id)
      end


      private


        def set_cache_entry(command, output, repo_id)
          begin
            GitCache.create(
              command:         command,
              command_output:  output,
              repo_identifier: repo_id
            )
          rescue => e
            logger.error("Could not insert in cache, this is the error : '#{e.message}'")
          else
            apply_cache_limit
          end
        end


        def get_cache_entry(primary_key, secondary_key)
          GitCache.find_by_command(compose_key(primary_key, secondary_key))
        end


        def valid_cache_entry?(cached)
          current_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
          expired = (current_time.to_i - cached.created_at.to_i < max_cache_time)
          (!expired || max_cache_time < 0) ? true : false
        end


        def apply_cache_limit
          GitCache.find(:last, order: 'created_at DESC').destroy if max_cache_elements >= 0 && GitCache.count > max_cache_elements
        end


        def compose_key(key1, key2)
          if key2 && !key2.blank?
            key1 + "\n" + key2
          else
            key1
          end
        end


        def do_clear_obsolete_cache_entries(limit)
          deleted = GitCache.delete_all(['created_at < ?', limit])
          logger.info("Removed '#{deleted}' expired cache entries among all repositories")
        end


        def do_clear_cache_for_repository(repo_id)
          deleted = GitCache.delete_all(['repo_identifier = ?', repo_id])
          logger.info("Removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
        end


        def logger
          RedmineGitHosting.logger
        end

    end

  end
end
