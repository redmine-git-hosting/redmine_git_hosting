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

		add_column :repositories, :git_daemon_pull, :integer, :default =>0
		add_column :repositories, :git_http_pull, :integer, :default=>0
		add_column :repositories, :git_http_push, :integer, :default=>0

	end

	def self.down
		drop_table :gitolite_public_keys
  		
		remove_column :repositories, :git_daemon_pull
		remove_column :repositories, :git_http_pull
		remove_column :repositories, :git_http_push
	end
end
