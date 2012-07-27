require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'sys_controller'

module GitHosting
	module Patches
		module SysControllerPatch
			def fetch_changesets_with_disable_update
				# Turn of updates during repository update
				GitHostingObserver.set_update_active(false);

				# Do actual update
				fetch_changesets_without_disable_update

				# Perform the updating process on all projects
				GitHostingObserver.set_update_active(:resync_all);
			end

			def self.included(base)
				base.class_eval do
					unloadable
				end
				begin
					base.send(:alias_method_chain, :fetch_changesets, :disable_update)
				rescue
				end
			end
		end
	end
end

# Patch in changes
SysController.send(:include, GitHosting::Patches::SysControllerPatch)
