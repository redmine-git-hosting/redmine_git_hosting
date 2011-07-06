require_dependency 'groups_controller'
module GitHosting
	module Patches
		module GroupsControllerPatch
			
			@@original_projects = []

			def disable_git_observer_updates
				@group = Group.find(params[:id])
				GitHostingObserver.set_update_active(false)
				@@original_projects = @group.users.map(&:projects).flatten.uniq.compact
			end
			
			def do_single_update
				new_projects = []
				if(@group != nil)
					new_projects = @group.users.map(&:projects).flatten.uniq.compact
				end
				new_projects.concat(@@original_projects)
				all_projects = new_projects.uniq.compact


				@@original_projects = []
				GitHostingObserver.set_update_active(true) 
				GitHosting::update_repositories(all_projects, false)
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
