module RedmineGitHosting
  module Patches
    module SysControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :fetch_changesets, :git_hosting
        end
      end

      module InstanceMethods

        def fetch_changesets_with_git_hosting(&block)
          # Turn of updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          fetch_changesets_without_git_hosting(&block)

          # Perform the updating process on all projects
          GitHostingObserver.set_update_active(:resync_all)
        end

      end

    end
  end
end

unless SysController.included_modules.include?(RedmineGitHosting::Patches::SysControllerPatch)
  SysController.send(:include, RedmineGitHosting::Patches::SysControllerPatch)
end
