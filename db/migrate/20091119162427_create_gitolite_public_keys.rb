class CreateGitolitePublicKeys < ActiveRecord::Migration
	def self.up
		create_table :gitolite_public_keys do |t|
			t.column :title, :string
			t.column :identifier, :string
			t.column :key, :text
			t.column :active, :integer, :default => 1
			t.references :user
			t.timestamps
		end

		create_table( :git_repo_hosting_options, :id => false, :primary_key =>:repository_id) do |t|
			t.references :repository,
			t.column :git_daemon_active, :integer, :default => 0
			t.column :smart_http_pull, :integer, :default => 0
			t.column :smart_http_push, :integer, :default => 0
		end
	end

	def self.down
		drop_table :gitolite_public_keys
		drop_table :git_repo_hosting_options
  	end
end
