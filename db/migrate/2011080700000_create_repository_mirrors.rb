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
	end

	def self.down
		drop_table :repository_mirrors
	end
end
