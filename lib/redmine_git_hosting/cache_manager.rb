module RedmineGitHosting
  module CacheManager

    class << self

      def logger
        RedmineGitHosting.logger
      end


      def max_cache_time
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_time).to_i
      end


      def max_cache_elements
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_elements).to_i
      end


      def max_cache_size
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_size).to_i*1024*1024
      end


      # Primary interface: execute given command and send IO to block
      # options[:write_stdin] will derive caching key from data that block writes to io stream
      def execute(cmd_str, repo_id, options = {}, &block)
        if !options[:write_stdin] && out = check_cache(cmd_str)
          # Simple case -- have cached result that depends only on cmd_str
          block.call(out)
          retio = out
          status = nil
        else
          # Create redirector stream and call block
          redirector = RedmineGitHosting::Cache.new(cmd_str, repo_id, options)
          block.call(redirector)
          retio, status = redirector.exit_shell
        end

        if status && status.exitstatus.to_i != 0
          logger.error("Git exited with non-zero status : #{status.exitstatus}")
          raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "Git exited with non-zero status : #{status.exitstatus}"
        end

        return retio
      end


      def set_cache(repo_id, out_value, primary_key, secondary_key = nil)
        logger.debug("Inserting cache entry for repository '#{repo_id}'")
        logger.debug(compose_key(primary_key, secondary_key))

        begin
          GitCache.create(
            command:         compose_key(primary_key, secondary_key),
            command_output:  out_value,
            repo_identifier: repo_id
          )
        rescue => e
          logger.error("Could not insert in cache, this is the error : '#{e.message}'")
        else
          apply_cache_limit
        end
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


      # After resetting cache timing parameters -- delete entries that no-longer match
      def clear_obsolete_cache_entries
        return if max_cache_time < 0  # No expiration needed
        target_limit = Time.now - max_cache_time
        deleted = GitCache.delete_all(["created_at < ?", target_limit])
        logger.info("Removed '#{deleted}' expired cache entries among all repositories")
      end


      # Clear the cache entries for given repository
      def clear_cache_for_repository(repository)
        repo_id = repository.git_cache_id
        deleted = GitCache.delete_all(["repo_identifier = ?", repo_id])
        logger.info("Removed '#{deleted}' expired cache entries for repository '#{repo_id}'")
      end

    end

  end
end
