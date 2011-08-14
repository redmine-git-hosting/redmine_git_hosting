class ModifyGitHookKeys < ActiveRecord::Migration
	def self.up
		drop_table :git_hook_keys if self.table_exists?("git_hook_keys")

		create_table :git_hook_keys do |t|
			t.column :repository_id, :integer
			t.column :key, :binary
			t.column :ivector, :binary
		end
		Project.find(:all).each {|project|
			if project.repository.is_a?(Repository::Git)
				k = GitHookKey.new()
				k.repository = project.repository
				k.save
			end
		}
	end

	def self.down
		drop_table :git_hook_keys
	end

	def self.table_exists?(name)
		ActiveRecord::Base.connection.tables.include?(name)
	end
end
