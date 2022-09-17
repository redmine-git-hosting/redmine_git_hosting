# frozen_string_literal: true

module RedmineGitHosting
  module Config
    module GitoliteStorage
      extend self

      def gitolite_global_storage_dir
        get_setting :gitolite_global_storage_dir
      end

      def gitolite_redmine_storage_dir
        get_setting :gitolite_redmine_storage_dir
      end

      def gitolite_recycle_bin_dir
        get_setting :gitolite_recycle_bin_dir
      end

      def recycle_bin_dir
        File.join gitolite_home_dir, gitolite_recycle_bin_dir
      rescue StandardError
        nil
      end
    end

    extend Config::GitoliteStorage
  end
end
