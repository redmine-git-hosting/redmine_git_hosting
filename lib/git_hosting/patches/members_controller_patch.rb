require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'members_controller'

module GitHosting
    module Patches
	module MembersControllerPatch
	    def new_with_disable_update
		# Turn of updates during repository update
		GitHostingObserver.set_update_active(false);

		# Do actual update
		new_without_disable_update

		# Reenable updates to perform a single update
		GitHostingObserver.set_update_active(true);
	    end
	    def edit_with_disable_update
		# Turn of updates during repository update
		GitHostingObserver.set_update_active(false);

		# Do actual update
		edit_without_disable_update

		# Reenable updates to perform a single update
		GitHostingObserver.set_update_active(true);
	    end
	    def destroy_with_disable_update
		# Turn of updates during repository update
		GitHostingObserver.set_update_active(false);

		# Do actual update
		destroy_without_disable_update

		# Reenable updates to perform a single update
		GitHostingObserver.set_update_active(:delete => true);
	    end

	    def self.included(base)
		base.class_eval do
		    unloadable
		end
		begin
		    base.send(:alias_method_chain, :new, :disable_update)
		    base.send(:alias_method_chain, :edit, :disable_update)
		    base.send(:alias_method_chain, :destroy, :disable_update)
		rescue
		end
	    end
	end
    end
end

# Patch in changes
MembersController.send(:include, GitHosting::Patches::MembersControllerPatch)
