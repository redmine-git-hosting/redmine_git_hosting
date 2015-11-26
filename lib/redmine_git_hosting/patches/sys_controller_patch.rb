require_dependency 'sys_controller'

module RedmineGitHosting
  module Patches
    module SysControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineGitHosting::GitoliteAccessor::Methods)
        base.class_eval do
          alias_method_chain :fetch_changesets, :git_hosting
        end
      end


      module InstanceMethods

        def fetch_changesets_with_git_hosting(&block)
          # Flush GitCache
          gitolite_accessor.flush_git_cache

          # Previous routine
          fetch_changesets_without_git_hosting(&block)

          # Purge RecycleBin
          gitolite_accessor.purge_recycle_bin
        end

      end


    end
  end
end

unless SysController.included_modules.include?(RedmineGitHosting::Patches::SysControllerPatch)
  SysController.send(:include, RedmineGitHosting::Patches::SysControllerPatch)
end
