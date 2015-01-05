module RedmineGitHosting::Config

  module GitoliteCache

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_cache_max_time
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_time).to_i
      end


      def gitolite_cache_max_elements
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_elements).to_i
      end


      def gitolite_cache_max_size
        RedmineGitHosting::Config.get_setting(:gitolite_cache_max_size).to_i * 1024 * 1024
      end


      def gitolite_cache_adapter
        RedmineGitHosting::Config.get_setting(:gitolite_cache_adapter)
      end

    end

  end
end
