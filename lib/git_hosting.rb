require 'lockfile'
require 'net/ssh'
require 'tmpdir'

require 'gitolite_conf.rb'

module GitHosting

	@@web_user = nil

	def self.logger
		return RAILS_DEFAULT_LOGGER
	end

	def self.web_user
		if @@web_user.nil?
			@@web_user = (%x[whoami]).chomp.strip
		end
		return @@web_user
	end

	def self.sudo_git_to_web_user
		git_user = Setting.plugin_redmine_git_hosting['gitUser']
		if git_user == web_user
			return true
		end
		test = %x[#{GitHosting.git_user_runner} sudo -nu #{web_user} echo "yes" ]
		if test.match(/yes/)
			return true
		end
		logger.warn "Error while testing sudo_git_to_web_user: #{test}"
		return test
	end

	def self.sudo_web_to_git_user
		git_user = Setting.plugin_redmine_git_hosting['gitUser']
		if git_user == web_user
			return true
		end
		test = %x[sudo -nu #{git_user} echo "yes"]
		if test.match(/yes/)
			return true
		end
		logger.warn "Error while testing sudo_web_to_git_user: #{test}"
		return test
	end

	def self.get_full_parent_path(project, is_file_path)
		parent_parts = [];
		p = project
		while p.parent
			parent_id = p.parent.identifier.to_s
			parent_parts.unshift(parent_id)
			p = p.parent
		end
		return is_file_path ? File.join(parent_parts) : parent_parts.join("/")
	end

	def self.repository_name project
		return "#{get_full_parent_path(project, false)}/#{project.identifier}".sub(/^\//, "")
	end

	def self.add_route_for_project(p)

		if defined? map
			add_route_for_project_with_map p, map
		else
			ActionController::Routing::Routes.draw do |map|
				add_route_for_project_with_map p, map
			end
		end
	end
	def self.add_route_for_project_with_map(p,m)
		repo = p.repository
		if repo.is_a?(Repository::Git)
			repo_path=repo.url.split(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'])[1]
			m.connect repo_path,                  :controller => 'git_http', :p1 => '', :p2 =>'', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			m.connect repo_path,                  :controller => 'git_http', :p1 => '', :p2 =>'', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			m.connect repo_path + "/:p1",         :controller => 'git_http', :p2 => '', :p3 =>'', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			m.connect repo_path + "/:p1/:p2",     :controller => 'git_http', :p3 => '', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
			m.connect repo_path + "/:p1/:p2/:p3", :controller => 'git_http', :id=>"#{p[:identifier]}", :path=>"#{repo_path}"
		end
	end

	def self.get_tmp_dir
		@@git_hosting_tmp_dir ||= File.join(Dir.tmpdir, "redmine_git_hosting")
		if !File.directory?(@@git_hosting_tmp_dir)
			%x[mkdir -p "#{@@git_hosting_tmp_dir}"]
		end
		return @@git_hosting_tmp_dir
	end

	def self.git_exec_path
		return File.join(get_tmp_dir(), "run_git_as_git_user")
	end
	def self.gitolite_ssh_path
		return File.join(get_tmp_dir(), "gitolite_admin_ssh")
	end
	def self.git_user_runner_path
		return File.join(get_tmp_dir(), "run_as_git_user")
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
		logger.info "[RedmineGitHosting] Setting up #{get_tmp_dir()}"
		git_user=Setting.plugin_redmine_git_hosting['gitUser']
		gitolite_key=Setting.plugin_redmine_git_hosting['gitoliteIdentityFile']

		File.open(gitolite_ssh_path(), "w") do |f|
			f.puts "#!/bin/sh"
			f.puts "exec ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i #{gitolite_key} \"$@\""
		end

		##############################################################################################################################
		# So... older versions of sudo are completely different than newer versions of sudo
		# Try running sudo -i [user] 'ls -l' on sudo > 1.7.4 and you get an error that command 'ls -l' doesn't exist
		# do it on version < 1.7.3 and it runs just fine.  Different levels of escaping are necessary depending on which
		# version of sudo you are using... which just completely CRAZY, but I don't know how to avoid it
		#
		# Note: I don't know whether the switch is at 1.7.3 or 1.7.4, the switch is between ubuntu 10.10 which uses 1.7.2
		# and ubuntu 11.04 which uses 1.7.4.  I have tested that the latest 1.8.1p2 seems to have identical behavior to 1.7.4
		##############################################################################################################################
		sudo_version_str=%x[ sudo -V 2>&1 | head -n1 | sed 's/^.* //g' | sed 's/[a-z].*$//g' ]
		split_version = sudo_version_str.split(/\./)
		sudo_version = 100*100*(split_version[0].to_i) + 100*(split_version[1].to_i) + split_version[2].to_i
		sudo_version_switch = (100*100*1) + (100 * 7) + 3



		File.open(git_exec_path(), "w") do |f|
			f.puts '#!/bin/sh'
			f.puts "if [ \"\$(whoami)\" = \"#{git_user}\" ] ; then"
			f.puts '	cmd=$(printf "\\"%s\\" " "$@")'
			f.puts '	cd ~'
			f.puts '	eval "git $cmd"'
			f.puts "else"
			if sudo_version < sudo_version_switch
				f.puts '	cmd=$(printf "\\\\\\"%s\\\\\\" " "$@")'
				f.puts "	sudo -u #{git_user} -i eval \"git $cmd\""
			else
				f.puts '	cmd=$(printf "\\"%s\\" " "$@")'
				f.puts "	sudo -u #{git_user} -i eval \"git $cmd\""
			end
			f.puts 'fi'
		end

		# use perl script for git_user_runner so we can
		# escape output more easily
		File.open(git_user_runner_path(), "w") do |f|
			f.puts '#!/usr/bin/perl'
			f.puts ''
			f.puts 'my $command = join(" ", @ARGV);'
			f.puts ''
			f.puts 'my $user = `whoami`;'
			f.puts 'chomp $user;'
			f.puts 'if ($user eq "' + git_user + '")'
			f.puts '{'
			f.puts '	exec("cd ~ ; $command");'
			f.puts '}'
			f.puts 'else'
			f.puts '{'
			f.puts '	$command =~ s/\\\\/\\\\\\\\/g;'
			f.puts '	$command =~ s/"/\\\\"/g;'
			if sudo_version < sudo_version_switch
				f.puts '	exec("sudo -u ' + git_user + ' -i \"$command\"");'
			else
				f.puts '	exec("sudo -u ' + git_user + ' -i eval \"$command\"");'
			end
			f.puts '}'
		end

		File.chmod(0777, git_exec_path())
		File.chmod(0777, gitolite_ssh_path())
		File.chmod(0777, git_user_runner_path())

	end

	def self.move_repository(old_name, new_name)
		old_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{old_name}.git")
		new_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{new_name}.git")

		# create tmp dir, return cleanly if, for some reason, we don't have proper permissions
		local_dir = get_tmp_dir()

		#lock
		lockfile=File.new(File.join(local_dir,'redmine_git_hosting_lock'),File::CREAT|File::RDONLY)
		retries=5
		loop do
			break if lockfile.flock(File::LOCK_EX|File::LOCK_NB)
			retries-=1
			sleep 2
			if retries<=0
				return
			end
		end

		# clone/pull from admin repo
		if File.exists? "#{local_dir}/gitolite-admin"
			%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' fetch]
			%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' merge FETCH_HEAD]
		else
			%x[env GIT_SSH=#{gitolite_ssh()} git clone #{Setting.plugin_redmine_git_hosting['gitUser']}@#{Setting.plugin_redmine_git_hosting['gitServer']}:gitolite-admin.git #{local_dir}/gitolite-admin]
		end
		%x[chmod 700 "#{local_dir}/gitolite-admin" ]

		# rename in conf file
		conf = GitoliteConfig.new(File.join(local_dir, 'gitolite-admin', 'conf', 'gitolite.conf'))
		conf.rename_repo( old_name, new_name )
		conf.save

		# physicaly move the repo BEFORE committing/pushing conf changes to gitolite admin repo
		%x[#{git_user_runner} 'mdkir -p "#{new_path}"']
		%x[#{git_user_runner} 'rmdir "#{new_path}"']
		%x[#{git_user_runner} 'mv "#{old_path}" "#{new_path}"']


		# commit / push changes to gitolite admin repo
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' add keydir/*]
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' add conf/gitolite.conf]
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' config user.email '#{Setting.mail_from}']
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' config user.name 'Redmine']
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' commit -a -m 'updated by Redmine' ]
		%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' push ]




		# unlock
		lockfile.flock(File::LOCK_UN)

	end

	def self.update_repositories(projects, is_repo_delete)
		logger.debug "[RedmineGitHosting] updating repositories..."
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
			local_dir = get_tmp_dir()

			#lock
			lockfile=File.new(File.join(local_dir,'redmine_git_hosting_lock'),File::CREAT|File::RDONLY)
			retries=5
			loop do
				break if lockfile.flock(File::LOCK_EX|File::LOCK_NB)
				retries-=1
				sleep 2
				if retries<=0
					return
				end
			end



			# clone/pull from admin repo
			if File.exists? "#{local_dir}/gitolite-admin"
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' fetch]
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' merge FETCH_HEAD]
			else
				%x[env GIT_SSH=#{gitolite_ssh()} git clone #{Setting.plugin_redmine_git_hosting['gitUser']}@#{Setting.plugin_redmine_git_hosting['gitServer']}:gitolite-admin.git #{local_dir}/gitolite-admin]
			end
			%x[chmod 700 "#{local_dir}/gitolite-admin" ]
			conf = GitoliteConfig.new(File.join(local_dir, 'gitolite-admin', 'conf', 'gitolite.conf'))
			orig_repos = conf.all_repos
			new_repos = []
			changed = false

			projects.select{|p| p.repository.is_a?(Repository::Git)}.each do |project|

				repo_name = repository_name(project)

				#check for delete -- if delete we can just
				#delete repo, and ignore updating users/public keys
				if is_repo_delete
					if Setting.plugin_redmine_git_hosting['deleteGitRepositories'] == "true"
						conf.delete_repo(repo_name)
					end
				else
					#check whether we're adding a new repo
					if orig_repos[ repo_name ] == nil
						changed = true
						add_route_for_project(project)
						new_repos.push repo_name
					end


					# fetch users
					users = project.member_principals.map(&:user).compact.uniq
					write_users = users.select{ |user| user.allowed_to?( :commit_access, project ) }
					read_users = users.select{ |user| user.allowed_to?( :view_changesets, project ) && !user.allowed_to?( :commit_access, project ) }

					# write key files
					users.map{|u| u.gitolite_public_keys.active}.flatten.compact.uniq.each do |key|
						filename = File.join(local_dir, 'gitolite-admin/keydir',"#{key.identifier}.pub")
						unless File.exists? filename
							File.open(filename, 'w') {|f| f.write(key.key.gsub(/\n/,'')) }
							changed = true
						end
					end



					# delete inactives
					users.map{|u| u.gitolite_public_keys.inactive}.flatten.compact.uniq.each do |key|
						filename = File.join(local_dir, 'gitolite-admin/keydir',"#{key.identifier}.pub")
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
			end

			if conf.changed?
				conf.save
				changed = true
			end

			if changed
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' add keydir/*]
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' add conf/gitolite.conf]
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' config user.email '#{Setting.mail_from}']
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' config user.name 'Redmine']
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' commit -a -m 'updated by Redmine' ]
				%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' push ]

			end

			#set post recieve hooks
			#need to do this AFTER push, otherwise necessary repos may not be created yet
			if new_repos.length > 0
				logger.info "[RedmineGitHosting] New repository found, setting up \"post-receive\" hook..."
				server_test = %x[#{git_user_runner} 'sudo -u #{web_user} ruby #{RAILS_ROOT}/script/runner -e production "print \\\"good\\\""']

				if server_test.match(/good/)
					new_repos.each do |repo_name|
						proj_name=repo_name.gsub(/^.*\//, '')
						hook_file=Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'] + repo_name + ".git/hooks/post-receive"
						%x[#{git_user_runner} 'echo "#!/bin/sh" > #{hook_file}' ]
						%x[#{git_user_runner} 'echo "sudo -u #{web_user} ruby #{RAILS_ROOT}/script/runner -e production \\\"GitHosting::run_post_update_hook(\\\\\\\"#{proj_name}\\\\\\\")\\\" >/dev/null 2>&1" >>#{hook_file}']
						%x[#{git_user_runner} 'chmod 700 #{hook_file} ']
					end
					logger.error "[RedmineGitHosting] Hook setup completed"
				else
					logger.error "[RedmineGitHosting] An error ocurred, see above"
				end
			end

			lockfile.flock(File::LOCK_UN)
		end
		@recursionCheck = false

	end


	def self.run_post_update_hook proj_identifier
		Repository.fetch_changesets_for_project(proj_identifier)
	end

end

