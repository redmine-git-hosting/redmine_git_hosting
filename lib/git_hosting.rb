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

			lockfile=File.new(File.join(RAILS_ROOT,"tmp",'redmine_gitolite_lock'),File::CREAT|File::RDONLY)
			retries=5
			loop do
				break if lockfile.flock(File::LOCK_EX|File::LOCK_NB)
				retries-=1
				sleep 2
				raise Lockfile::MaxTriesLockError if retries<=0
			end


			# HANDLE GIT

			# create tmp dir
			local_dir = File.join(RAILS_ROOT, "tmp","redmine_gitolite_#{Time.now.to_i}")
			%x[mkdir "#{local_dir}"]

			# Create GIT_SSH script
			git_env_ssh=""
			if not mswin?
				#setup custom ssh file to use specified ssh key
				ssh_with_identity_file = File.join(local_dir, 'ssh_with_identity_file.sh')
				File.open(ssh_with_identity_file, "w") do |f|
					f.puts "#!/bin/bash"
					f.puts "exec ssh -o stricthostkeychecking=no -i #{Setting.plugin_redmine_git_hosting['gitoliteIdentityFile']} \"$@\""
				end
				File.chmod(0755, ssh_with_identity_file)
				ENV['GIT_SSH'] = ssh_with_identity_file
				env_git_ssh="env GIT_SSH=#{ssh_with_identity_file} "
			end

			# clone admin repo
			%x[#{env_git_ssh} git clone #{Setting.plugin_redmine_git_hosting['gitUser']}@#{Setting.plugin_redmine_git_hosting['gitServer']}:gitolite-admin.git #{local_dir}/gitolite]

			conf = GitoliteConfig.new(File.join(local_dir, 'gitolite', 'conf', 'gitolite.conf'))

			changed = false
			projects.select{|p| p.repository.is_a?(Repository::Git)}.each do |project|
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
						File.unlink() rescue nil
						changed = true
					end
				end

				# update users
				repo_name = repository_name(project)
				read_users = read_users.map{|u| u.login.underscore}
				write_users = write_users.map{|u| u.login.underscore}

				#git daemon
				if repository.git_daemon == 1 && repository.is_public
					read_users.push "daemon"
				end

				conf.set_read_user repo_name, read_users
				conf.set_write_user repo_name, write_users	
			end
			
			if conf.changed?
				conf.save
				changed = true
			end

			if changed
				git_push_file = File.join(local_dir, 'git_push.bat')
				new_dir= File.join(local_dir,'gitolite')
				
				File.open(git_push_file, "w") do |f|
					f.puts "#!/bin/sh" if not mswin?
					f.puts "cd #{new_dir}"
					f.puts "git add keydir/*"
					f.puts "git add conf/gitolite.conf"
					f.puts "git config user.email '#{Setting.mail_from}'"
					f.puts "git config user.name 'Redmine'"
					f.puts "git commit -a -m 'updated by Redmine'"
					f.puts "#{env_git_ssh}git push"
				end
				File.chmod(0755, git_push_file)

				# add, commit, push, and remove local tmp dir
				%x[sh #{git_push_file}]
			end
			# remove local copy
			%x[rm -Rf #{local_dir}]

			lockfile.flock(File::LOCK_UN)
		end
		@recursionCheck = false

	end

	def self.mswin?  # copy & paste from redmine/extra/svn/reposman.rb:mswin?
		(RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
	end
end

