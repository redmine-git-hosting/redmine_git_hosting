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
        command = compose_key(primary_key, secondary_key)
        adapter.apply_cache_limit(max_cache_elements) if adapter.set_cache(command, out_value, repo_id)
      end


      def get_cache(primary_key, secondary_key = nil)
        command = compose_key(primary_key, secondary_key)
        cached  = adapter.get_cache(command)

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

        # Return result as a string stream
        out.nil? ? nil : StringIO.new(out)
      end


      # After resetting cache timing parameters -- delete entries that no-longer match
      def clear_obsolete_cache_entries
        return if max_cache_time < 0  # No expiration needed
        limit = Time.now - max_cache_time
        adapter.clear_obsolete_cache_entries(limit)
      end


      # Clear the cache entries for given repository / git_cache_id
      def clear_cache_for_repository(repo_id)
        adapter.clear_cache_for_repository(repo_id)
      end


      def adapter
        @adapter ||= Cache::Adapter.factory
      end


      private


        def valid_cache_entry?(cached_entry_date)
          current_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
          expired = (current_time.to_i - cached_entry_date.to_i > max_cache_time)
          (!expired || max_cache_time < 0) ? true : false
        end


        def compose_key(key1, key2)
          if key2 && !key2.blank?
            key1 + "\n" + key2
          else
            key1
          end
        end

    end

  end
end
