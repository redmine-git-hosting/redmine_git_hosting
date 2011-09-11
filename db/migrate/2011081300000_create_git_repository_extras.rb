class CreateGitRepositoryExtras < ActiveRecord::Migration
	def self.up

		drop_table :git_repository_extras if self.table_exists?("git_repository_extras")

		create_table :git_repository_extras do |t|
			t.column :repository_id, :integer
			# from repository extra columns
			t.column :git_daemon, :integer, :default =>1
			t.column :git_http, :integer, :default=>1
			t.column :notify_cia, :integer, :default=>0
			# from Hooks Keys table
			t.column :key, :string
		end


		GitHostingObserver.set_update_active(false)
		Project.find(:all).each do |project|
			if project.repository.is_a?(Repository::Git)

				#create extra object
				e = GitRepositoryExtra.new()
				begin
					e.git_daemon = project.repository.git_daemon || 1
					e.git_http = project.repository.git_http || 1
					e.key = project.repository.hook_key.key
				rescue
					e.git_daemon = 1
					e.git_http = 1
				end
				e.repository_id = project.repository.id
				e.save

				#update repo url to match location of gitolite repos
				r = project.repository
				repo_name= project.parent ? File.join(GitHosting::get_full_parent_path(project, true),project.identifier) : project.identifier
				r.url = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{repo_name}.git")
				r.root_url = r.url
				r.extra = e
				r.save

			end
		end

		# this next part requires running commands as git user
		# use a begin/rescue block because this could easily bomb out
		# if settings aren't correct to begin with
		begin
			%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]
			GitHosting.setup_hooks
			GitHostingObserver.set_update_active(false)
		rescue
		end

		# even if git commands above didn't work properly, attempt to
		# eliminate tmp dir in case they partially worked, and we have
		# residual crap belonging to wrong user
		begin
			%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]
		rescue
		end


		if self.table_exists?("git_hook_keys")
			drop_table :git_hook_keys
		end
		if self.column_exists?(:repositories, :git_daemon)
			remove_column :repositories, :git_daemon
		end
		if self.column_exists?(:repositories, :git_http)
			remove_column :repositories, :git_http
		end

	end

	def self.down
		drop_table :git_repository_extras
	end

	def self.table_exists?(name)
		ActiveRecord::Base.connection.tables.include?(name)
	end
	def self.column_exists?(table_name, column_name)
		columns(table_name).any?{ |c| c.name == column_name.to_s }
	end
end
