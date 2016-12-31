require_dependency 'sys_controller'

module RedmineGitHosting
  module Patches
    module SysControllerPatch

      include RedmineGitHosting::GitoliteAccessor::Methods

      def fetch_changesets
        # Flush GitCache
        gitolite_accessor.flush_git_cache

        super

        # Purge RecycleBin
        gitolite_accessor.purge_recycle_bin
      end

    end
  end
end

unless SysController.included_modules.include?(RedmineGitHosting::Patches::SysControllerPatch)
  SysController.send(:prepend, RedmineGitHosting::Patches::SysControllerPatch)
end
