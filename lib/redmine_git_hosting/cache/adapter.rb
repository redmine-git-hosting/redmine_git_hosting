module RedmineGitHosting::Cache
  module Cache
    module Adapter
      extend self

      def factory
        case RedmineGitHosting::Config.gitolite_cache_adapter
        when 'database'
          Database.new
        when 'memcached'
          Memcached.new
        when 'redis'
          Redis.new
        end
      end

    end
  end
end
