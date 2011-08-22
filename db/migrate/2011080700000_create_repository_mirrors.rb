class CreateRepositoryMirrors < ActiveRecord::Migration
	def self.up
		create_table :repository_mirrors do |t|
			t.column :project_id, :integer
			t.column :active, :integer, :default => 1
			t.column :url, :string
			t.column :private_key, :string, :limit => 1700
			t.references :project
			t.timestamps
		end
		
		manager_role   = Role.find_by_name("Manager")
		manager_role.add_permission! :view_repository_mirrors
		manager_role.add_permission! :edit_repository_mirrors
		manager_role.add_permission! :create_repository_mirrors
		manager_role.save
		
		developer_role = Role.find_by_name("Developer")
		developer_role.add_permission! :view_repository_mirrors
		developer_role.save		
		
	end

	def self.down
		drop_table :repository_mirrors
	end
end
