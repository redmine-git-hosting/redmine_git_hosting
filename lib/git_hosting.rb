require 'lockfile'
require 'net/ssh'
require 'tmpdir'

require 'gitolite_conf.rb'

module GitHosting
	def self.repository_name project
		parent_name = project.parent ? repository_name(project.parent) : ""
		return "#{parent_name}/#{project.identifier}".sub(/^\//, "")
	end
	
	def self.get_urls(project)
		urls = {:read_only => [], :developer => []}
		read_only_baseurls = Setting.plugin_redmine_git_hosting['readOnlyBaseUrls'].split(/[\r\n\t ,;]+/)
		developer_baseurls = Setting.plugin_redmine_git_hosting['developerBaseUrls'].split(/[\r\n\t ,;]+/)

		project_path = repository_name(project) + ".git"

		read_only_baseurls.each {|baseurl| urls[:read_only] << baseurl + project_path}
		developer_baseurls.each {|baseurl| urls[:developer] << baseurl + project_path}
		return urls
	end

	def self.git_exec_path
		return File.join(RAILS_ROOT, "run_git_as_git_user")
	end
	def self.gitolite_ssh_path
		return File.join(RAILS_ROOT, "gitolite_admin_ssh")
	end
	def self.git_user_runner_path
		return File.join(RAILS_ROOT, "run_as_git_user")
	end

	def self.git_exec
		if !File.exists?(git_exec_path())
			update_git_exec
		end
		return git_exec_path()
	end
	def self.gitolite_ssh
		if !File.exists?(gitolite_ssh_path())
			update_git_exec
		end
		return gitolite_ssh_path()
	end
	def self.git_user_runner
		if !File.exists?(git_user_runner_path())
			update_git_exec
		end
		return git_user_runner_path()
	end

	def self.update_git_exec
		git_user_server=Setting.plugin_redmine_git_hosting['gitUser'] + "@" + Setting.plugin_redmine_git_hosting['gitServer']
		git_user_key=Setting.plugin_redmine_git_hosting['gitUserIdentityFile']
		gitolite_key=Setting.plugin_redmine_git_hosting['gitoliteIdentityFile']
		File.open(git_exec_path(), "w") do |f|
			f.puts "#!/bin/sh"
			f.puts "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i #{git_user_key} #{git_user_server} \"git $@\""
		end
		File.open(gitolite_ssh_path(), "w") do |f|
			f.puts "#!/bin/sh"
			f.puts "exec ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i #{gitolite_key} \"$@\""
		end
		File.open(git_user_runner_path(), "w") do |f|
			f.puts "#!/bin/sh"
			f.puts "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i #{git_user_key} #{git_user_server} \"$@\""
		end

		File.chmod(0700, git_exec_path())
		File.chmod(0700, gitolite_ssh_path())
		File.chmod(0700, git_user_runner_path())

	end

	def self.update_repositories(projects)
		projects = (projects.is_a?(Array) ? projects : [projects])

		if(defined?(@recursionCheck))
			if(@recursionCheck)
				return
			end
		end
		@recursionCheck = true

		# Don't bother doing anything if none of the projects we've been handed have a Git repository
		unless projects.detect{|p|  p.repository.is_a?(Repository::Git) }.nil?
			
			# create tmp dir, return cleanly if, for some reason, we don't have proper permissions
			local_dir = File.join(RAILS_ROOT, "tmp","redmine_gitolite_#{Time.now.to_i}")
			%x[mkdir "#{local_dir}"]
			if !File.exists local_dir
				return
			end

			#lock
			lockfile=File.new(File.join(RAILS_ROOT,"tmp",'redmine_gitolite_lock'),File::CREAT|File::RDONLY)
			retries=5
			loop do
				break if lockfile.flock(File::LOCK_EX|File::LOCK_NB)
				retries-=1
				sleep 2
				if retries<=0
					%x[rm -Rf #{local_dir}]
					return
				end
			end


			# clone admin repo
			%x[env GIT_SSH=#{gitolite_ssh()} git clone #{Setting.plugin_redmine_git_hosting['gitUser']}@#{Setting.plugin_redmine_git_hosting['gitServer']}:gitolite-admin.git #{local_dir}/gitolite]

			conf = GitoliteConfig.new(File.join(local_dir, 'gitolite', 'conf', 'gitolite.conf'))
			orig_repos = conf.all_repos
			new_repos = []
			changed = false

			projects.select{|p| p.repository.is_a?(Repository::Git)}.each do |project|
				
				#check whether we're adding a new repo
				repo_name = repository_name(project)
				if orig_repos[ repo_name ] == nil
					changed = true
					new_repos.push repo_name
				end
				
				# fetch users
				users = project.member_principals.map(&:user).compact.uniq
				write_users = users.select{ |user| user.allowed_to?( :commit_access, project ) }
				read_users = users.select{ |user| user.allowed_to?( :view_changesets, project ) && !user.allowed_to?( :commit_access, project ) }
				
				# write key files
				users.map{|u| u.gitolite_public_keys.active}.flatten.compact.uniq.each do |key|
					filename = File.join(local_dir, 'gitolite/keydir',"#{key.identifier}.pub")
					unless File.exists? filename
						File.open(filename, 'w') {|f| f.write(key.key.gsub(/\n/,'')) }
						changed = true
					end
				end

				# delete inactives
				users.map{|u| u.gitolite_public_keys.inactive}.flatten.compact.uniq.each do |key|
					filename = File.join(local_dir, 'gitolite/keydir',"#{key.identifier}.pub")
					if File.exists? filename
						File.unlink(filename) rescue nil
						changed = true
					end
				end

				# update users
				read_user_keys = []
				write_user_keys = []
				read_users.map{|u| u.gitolite_public_keys.active}.flatten.compact.uniq.each do |key|
					read_user_keys.push key.identifier
				end
				write_users.map{|u| u.gitolite_public_keys.active}.flatten.compact.uniq.each do |key|
					write_user_keys.push key.identifier
				end


				#git daemon
				if (project.repository.git_daemon == 1 || project.repository.git_daemon == nil )  && project.is_public
					read_user_keys.push "daemon"
				end

				conf.set_read_user repo_name, read_user_keys
				conf.set_write_user repo_name, write_user_keys	
			end
			
			if conf.changed?
				conf.save
				changed = true
			end

			if changed
				git_push_file = File.join(local_dir, 'git_push.bat')
				new_dir= File.join(local_dir,'gitolite')
				File.open(git_push_file, "w") do |f|
					f.puts "#!/bin/sh" 
					f.puts "cd #{new_dir}"
					f.puts "git add keydir/*"
					f.puts "git add conf/gitolite.conf"
					f.puts "git config user.email '#{Setting.mail_from}'"
					f.puts "git config user.name 'Redmine'"
					f.puts "git commit -a -m 'updated by Redmine'"
					f.puts "env GIT_SSH=#{gitolite_ssh()} git push"
				end
				File.chmod(0755, git_push_file)

				# add, commit, push, and remove local tmp dir
				%x[sh #{git_push_file}]
			end

			#set post recieve hooks
			#need to do this AFTER push, otherwise necessary repos may not be created yet
			if new_repos.length > 0
				server_test = %x[#{git_user_runner} 'ruby #{RAILS_ROOT}/script/runner -e production "print \\\"good\\\"" 2>/dev/null']
				if server_test.match(/good/)
					new_repos.each do |repo_name|
						hook_file=Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'] + repo_name + ".git/hooks/post-receive"
						%x[#{git_user_runner} 'echo "#!/bin/sh" > #{hook_file} ; echo "ruby #{RAILS_ROOT}/script/runner -e production Repository.fetch_changesets >/dev/null 2>&1" >>#{hook_file} ; chmod 700 #{hook_file} ']
					end
				end
			end

			# remove local copy
			%x[rm -Rf #{local_dir}]

			lockfile.flock(File::LOCK_UN)
		end
		@recursionCheck = false

	end

end

