class CreateGitCaches < ActiveRecord::Migration
	def self.up
		create_table :git_caches do |t|
			t.column :command, :string
			t.column :output, :text
			t.column :used_count, :integer, :default =>1
			t.timestamps
			t.index :command 
		end
	end

	def self.down
		drop_table :git_caches
	end
end
