module RedmineGitHosting
  module Config
    module GitoliteCache
      extend self

      def gitolite_cache_max_time
        get_setting(:gitolite_cache_max_time).to_i
      end


      def gitolite_cache_max_elements
        get_setting(:gitolite_cache_max_elements).to_i
      end


      def gitolite_cache_max_size
        get_setting(:gitolite_cache_max_size).to_i * 1024 * 1024
      end


      def gitolite_cache_adapter
        get_setting(:gitolite_cache_adapter)
      end

    end
  end
end
