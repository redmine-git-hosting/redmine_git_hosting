require_dependency 'groups_controller'
module GitHosting
	module Patches
		module GroupsControllerPatch
			
			@@original_projects = nil

			def disable_git_observer_updates
				
			end
			
			def do_single_update
			

				@@original_projects = nil
			end


			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:before_filter, :disable_git_observer_updates, :only=>[:update, :destroy, :add_users, :remove_user, :edit_membership, :destroy_membership])
				base.send(:after_filter, :do_single_update,  :only=>[:update, :destroy, :add_users, :remove_user, :edit_membership, :destroy_membership])
			end
		end
	end
end
GroupsController.send(:include, GitHosting::Patches::GroupsControllerPatch) unless GroupsController.include?(GitHosting::Patches::GroupsControllerPatch)
