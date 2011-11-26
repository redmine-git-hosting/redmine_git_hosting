module GitHosting
	module Patches
		module UsersControllerPatch
                        def create_with_disable_update
                             	# Turn of updates during repository update
                       		GitHostingObserver.set_update_active(false);

                       		# Do actual update
                       		create_without_disable_update

                       		# Reenable updates to perform a single update
				GitHostingObserver.set_update_active(true);
                       	end
                        def update_with_disable_update
                             	# Turn of updates during repository update
                       		GitHostingObserver.set_update_active(false);

                       		# Do actual update
                       		update_without_disable_update

                       		# Reenable updates to perform a single update
				GitHostingObserver.set_update_active(true);
                       	end
                        def destroy_with_disable_update
                             	# Turn of updates during repository update
                       		GitHostingObserver.set_update_active(false);

                       		# Do actual update
                       		destroy_without_disable_update

                       		# Reenable updates to perform a single update
				GitHostingObserver.set_update_active(true);
                       	end
                        def edit_membership_with_disable_update
                             	# Turn of updates during repository update
                       		GitHostingObserver.set_update_active(false);

                       		# Do actual update
                       		edit_membership_without_disable_update

                       		# Reenable updates to perform a single update
				GitHostingObserver.set_update_active(true);
                       	end

			def self.included(base)
				base.class_eval do
					unloadable
				end
                        	begin
                                	base.send(:alias_method_chain, :create, :disable_update)
                                	base.send(:alias_method_chain, :update, :disable_update)
                                	base.send(:alias_method_chain, :destroy, :disable_update)
                                	base.send(:alias_method_chain, :edit_membershipt, :disable_update)
                                rescue
                                end
			end
		end
	end
end
