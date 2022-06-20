# frozen_string_literal: true

module RedmineGitHosting
  module Cache
    class AbstractCache
      class << self
        def max_cache_size
          @max_cache_size ||= RedmineGitHosting::Config.gitolite_cache_max_size
        end

        def max_cache_time
          @max_cache_time ||= RedmineGitHosting::Config.gitolite_cache_max_time
        end

        def max_cache_elements
          @max_cache_elements ||= RedmineGitHosting::Config.gitolite_cache_max_elements
        end

        def set_cache(repo_id, command, output)
          raise NotImplementedError
        end

        def get_cache(repo_id, command)
          raise NotImplementedError
        end

        def flush_cache!
          raise NotImplementedError
        end

        def clear_obsolete_cache_entries
          raise NotImplementedError
        end

        def clear_cache_for_repository(repo_id)
          raise NotImplementedError
        end

        def apply_cache_limit
          raise NotImplementedError
        end

        private

        def logger
          RedmineGitHosting.logger
        end

        def time_limit
          return if max_cache_time.to_i.negative? # No expiration needed

          current_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.zone.now
          current_time - max_cache_time
        end

        def valid_cache_entry?(cached_entry_date)
          return true if max_cache_time.to_i.negative? # No expiration needed

          current_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.zone.now
          expired = current_time.to_i - cached_entry_date.to_i > max_cache_time
          !expired
        end
      end
    end
  end
end
