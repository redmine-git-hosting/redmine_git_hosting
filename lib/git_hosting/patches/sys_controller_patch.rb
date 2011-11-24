module GitHosting
	module Patches
		module SysControllerPatch
                        def fetch_changesets_with_disable_update
                             	# Turn of updates during repository update
                       		GitHostingObserver.set_update_active(false);

                       		# Do actual update
                       		fetch_changesets_without_disable_update

                       		# Reenable updates to perform a single update
				GitHostingObserver.set_update_active(true);
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
