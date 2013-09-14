module RedmineGitHosting
  module Patches
    module RepositoryGitPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :report_last_commit,       :git_hosting
          alias_method_chain :extra_report_last_commit, :git_hosting
          alias_method_chain :fetch_changesets,         :git_hosting

          before_validation  :set_git_urls
        end
      end

      module InstanceMethods

        def report_last_commit_with_git_hosting
          # Always true
          true
        end

        def extra_report_last_commit_with_git_hosting
          # Always true
          true
        end

        def fetch_changesets_with_git_hosting(&block)
          # Turn of updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          fetch_changesets_without_git_hosting(&block)

          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(true)
        end

        private

        # Set up git urls for new repositories
        def set_git_urls
          self.url = GitHosting.repository_path(self) if self.url.blank?
          self.root_url = self.url if self.root_url.blank?
        end

      end

    end
  end
end

unless Repository::Git.included_modules.include?(RedmineGitHosting::Patches::RepositoryGitPatch)
  Repository::Git.send(:include, RedmineGitHosting::Patches::RepositoryGitPatch)
end
