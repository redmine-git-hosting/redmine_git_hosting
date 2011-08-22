class SetMirrorRolePermissions < ActiveRecord::Migration
	def self.up
		
		GitHostingObserver.set_update_active(false)

		manager_role   = Role.find_by_name("Manager")
		manager_role.remove_permission! :view_repository_mirrors
		manager_role.remove_permission! :edit_repository_mirrors
		manager_role.remove_permission! :create_repository_mirrors
		manager_role.save
		
		developer_role = Role.find_by_name("Developer")
		developer_role.remove_permission! :view_repository_mirrors
		developer_role.save		
		
	end

	def self.down
		
		GitHostingObserver.set_update_active(false)
	
		manager_role   = Role.find_by_name("Manager")
		manager_role.remove_permission! :view_repository_mirrors
		manager_role.remove_permission! :edit_repository_mirrors
		manager_role.remove_permission! :create_repository_mirrors
		manager_role.save
		
		developer_role = Role.find_by_name("Developer")
		developer_role.remove_permission! :view_repository_mirrors
		developer_role.save	
	end
end
