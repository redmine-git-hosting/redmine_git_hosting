module RedmineGitHosting
  module Config
    module RedmineConfig
      extend self

      def gitolite_use_sidekiq?
        get_setting(:gitolite_use_sidekiq, true)
      end

      def sidekiq_available?
        @sidekiq_available ||=
          begin
            require 'sidekiq'
            require 'sidekiq/api'
          rescue LoadError
            false
          else
            true
          end
      end

      def hierarchical_organisation?
        get_setting(:hierarchical_organisation, true)
      end

      def unique_repo_identifier?
        get_setting(:unique_repo_identifier, true)
      end

      def all_projects_use_git?
        get_setting(:all_projects_use_git, true)
      end

      def init_repositories_on_create?
        get_setting(:init_repositories_on_create, true)
      end

      def show_repositories_url?
        get_setting(:show_repositories_url, true)
      end

      def download_revision_enabled?
        get_setting(:download_revision_enabled, true)
      end

      def delete_git_repositories?
        get_setting(:delete_git_repositories, true)
      end

      def gitolite_recycle_bin_expiration_time
        (get_setting(:gitolite_recycle_bin_expiration_time).to_f * 60).to_i
      end
    end
  end
end
