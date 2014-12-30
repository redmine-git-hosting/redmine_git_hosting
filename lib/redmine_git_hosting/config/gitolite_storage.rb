module RedmineGitHosting::Config

  module GitoliteStorage

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_global_storage_dir
        RedmineGitHosting::Config.get_setting(:gitolite_global_storage_dir)
      end


      def gitolite_redmine_storage_dir
        RedmineGitHosting::Config.get_setting(:gitolite_redmine_storage_dir)
      end


      def gitolite_recycle_bin_dir
        RedmineGitHosting::Config.get_setting(:gitolite_recycle_bin_dir)
      end

    end

  end
end
