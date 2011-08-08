class CreateGitHostingRepositoryMirrors < ActiveRecord::Migration
	def self.up
		create_table :git_hosting_repository_mirrors do |t|
			t.column :repository_id, :integer
			t.column :public_key_id, :integer
			t.column :active, :integer, :default => 1
			t.column :url, :string
			t.references :repository
			t.references :gitolite_public_key
			t.timestamps
		end
	end

	def self.down
		drop_table :git_hosting_repository_mirrors
	end
end
