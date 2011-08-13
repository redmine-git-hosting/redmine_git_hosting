class CreateGitRepositoryExtras < ActiveRecord::Migration
	def self.up

		drop_table :git_repository_extras if self.table_exists?("git_repository_extras")

		create_table :git_repository_extras do |t|
			t.column :repository_id, :integer
			# from repository extra columns
			t.column :git_daemon, :integer, :default =>1
			t.column :git_http, :integer, :default=>1
			# from Hooks Keys table
			t.column :key, :binary
			t.column :ivector, :binary
		end

		Project.find(:all).each {|project|
			if project.repository.is_a?(Repository::Git)
				e = GitRepositoryExtra.new()
				e.git_daemon = project.repository.git_daemon || 1
				e.git_http = project.repository.git_http || 1
				e.key = project.repository.hook_key.key
				e.ivector = project.repository.hook_key.ivector
				e.repository = project.repository
				e.save
			end
		}

		#drop_table :git_hook_keys
		#remove_column :repositories, :git_daemon
		#remove_column :repositories, :git_http

	end

	def self.down
		if not self.table_exists?("git_hook_keys")
			create_table :git_hook_keys do |t|
				t.column :repository_id, :integer
				t.column :key, :binary
				t.column :ivector, :binary
			end
		end

		if not column_exists?(:repositories, :git_daemon)
			add_column :repositories, :git_daemon, :integer, :default =>1
		end
		if not column_exists?(:repositories, :git_http)
			add_column :repositories, :git_http, :integer, :default =>1
		end

		GitRepositoryExtra.find(:all).each { |extra|
			extra.repository.git_http = extra.git_http
			extra.repository.git_daemon = extra.git_daemon
			extra.repository.save
			k = GitHookKey.new()
			k.key = extra.key
			k.ivector = extra.ivector
			k.repository = extra.repository
			k.save
		}
		drop_table :git_repository_extras

	end

	def self.table_exists?(name)
		ActiveRecord::Base.connection.tables.include?(name)
	end
end
