class CreateGitHookKeys < ActiveRecord::Migration
	def self.up
		create_table :git_hook_keys do |t|
			t.column :update_key, :string
		end
	end

	def self.down
		drop_table :git_hook_keys
	end
end
