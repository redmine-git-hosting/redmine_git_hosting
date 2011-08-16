require 'lockfile'
require 'net/ssh'
require 'tempfile'
require 'tmpdir'

require 'gitolite_conf.rb'

module GitHosting

	class GitHostingLogger < Logger
		# This is not the buffered logger used in rails on purpose, the idea is to log as soon as we get
		# the messages, yet, this has a performance penalty, only enable it if your having troubles.
		def format_message(severity, timestamp, progname, msg)
			"[%s] %-5s [%s] %s\n" % [timestamp.to_formatted_s(:db), severity, progname, msg]
		end
	end

	@@logger = nil
	def self.logger
		if @@logger.nil?
			@@logger = GitHostingLogger.new(
				(Setting.plugin_redmine_git_hosting['loggingEnabled'] == 'true')?
					((Rails.configuration.environment == "production")? STDERR : STDOUT) : '/dev/null')
			@@logger.level = Setting.plugin_redmine_git_hosting['loggingLevel'].to_i || GitHostingLogger::DEBUG
			@@logger.progname = 'RedmineGitHosting'
		end
		return @@logger
	end

	@@web_user = nil
	def self.web_user
		if @@web_user.nil?
			@@web_user = (%x[whoami]).chomp.strip
		end
		return @@web_user
	end

	def self.git_user
		Setting.plugin_redmine_git_hosting['gitUser']
	end

	@@sudo_git_to_web_user_stamp = nil
	@@sudo_git_to_web_user_cached = nil
	def self.sudo_git_to_web_user
		if not @@sudo_git_to_web_user_cached.nil? and (Time.new - @@sudo_git_to_web_user_stamp <= 0.5):
			return @@sudo_git_to_web_user_cached
		end
		logger.info "Testing if git user(\"#{git_user}\") can sudo to web user(\"#{web_user}\")"
		if git_user == web_user
			@@sudo_git_to_web_user_cached = true
			@@sudo_git_to_web_user_stamp = Time.new
			return @@sudo_git_to_web_user_cached
		end
		test = %x[#{GitHosting.git_user_runner} sudo -nu #{web_user} echo "yes" ]
		if test.match(/yes/)
			@@sudo_git_to_web_user_cached = true
			@@sudo_git_to_web_user_stamp = Time.new
			return @@sudo_git_to_web_user_cached
		end
		logger.warn "Error while testing sudo_git_to_web_user: #{test}"
		@@sudo_git_to_web_user_cached = test
		@@sudo_git_to_web_user_stamp = Time.new
		return @@sudo_git_to_web_user_cached
	end

	@@sudo_web_to_git_user_stamp = nil
	@@sudo_web_to_git_user_cached = nil
	def self.sudo_web_to_git_user
		if not @@sudo_web_to_git_user_cached.nil? and (Time.new - @@sudo_web_to_git_user_stamp <= 0.5):
			return @@sudo_web_to_git_user_cached
		end
		logger.info "Testing if web user(\"#{web_user}\") can sudo to git user(\"#{git_user}\")"
		if git_user == web_user
			@@sudo_web_to_git_user_cached = true
			@@sudo_web_to_git_user_stamp = Time.new
			return @@sudo_web_to_git_user_cached
		end
		test = %x[sudo -nu #{git_user} echo "yes"]
		if test.match(/yes/)
			@@sudo_web_to_git_user_cached = true
			@@sudo_web_to_git_user_stamp = Time.new
			return @@sudo_web_to_git_user_cached
		end
		logger.warn "Error while testing sudo_web_to_git_user: #{test}"
		@@sudo_web_to_git_user_cached = test
		@@sudo_web_to_git_user_stamp = Time.new
		return @@sudo_web_to_git_user_cached
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

	def self.repository_path project
		return File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], repository_name(project))
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
			%x[chmod 770 "#{@@git_hosting_tmp_dir}"]
			%x[chown #{web_user}:#{git_user} "#{@@git_hosting_tmp_dir}"]
		end
		return @@git_hosting_tmp_dir
	end

	def self.get_mirror_identities_dir
		@@mirror_identities_dir = File.join(@@git_hosting_tmp_dir, 'mirror_identities')
		if !File.directory?(@@mirror_identities_dir)
			%x[#{git_user_runner} 'mkdir -p "#{@@mirror_identities_dir}"']
			%x[#{git_user_runner} 'chmod 0750 "#{@@mirror_identities_dir}"']
		end
		return @@mirror_identities_dir
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
	def self.git_exec_mirror_path
		return File.join(get_tmp_dir(), "run_git_under_another_identity")
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
	def self.git_exec_mirror
		if !File.exists?(git_exec_mirror_path())
			update_git_exec
		end
		return git_exec_mirror_path()
	end

	def self.git_mirror_identity_file(mirror)
		identity_file_path = File.join(get_mirror_identities_dir(), mirror.to_s)
		if !File.exists?(identity_file_path)
			if git_user == web_user
				File.open(identity_file_path, "w") do |f|
					f.puts "#{mirror.private_key}"
				end
			else
				file = Tempfile.new('')
				begin
					file.write(mirror.private_key)
					file.close
					%x[#{GitHosting.git_user_runner} 'sudo -nu #{web_user} cat #{file.path} | cat - >  #{identity_file_path}']
					%x[#{git_user_runner} 'chmod 0600 #{identity_file_path}']
				ensure
					file.unlink
				end
			end
		end
		return identity_file_path
	end

	def self.update_git_exec
		logger.info "Setting up #{get_tmp_dir()}"
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

		File.open(git_exec_mirror_path(), "w") do |f|
			f.puts '#!/bin/sh'
			f.puts "if [ \"\$(whoami)\" = \"#{git_user}\" ] ; then"
			f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
			f.puts '  cd ~'
			f.puts '  eval "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i ${GIT_MIRROR_IDENTITY_FILE} $cmd"'
			f.puts "else"
			if sudo_version < sudo_version_switch
				f.puts '  cmd=$(printf "\\\\\\"%s\\\\\\" " "$@")'
				f.puts "  sudo -u #{git_user} -i eval \"ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i ${GIT_MIRROR_IDENTITY_FILE} $cmd\""
			else
				f.puts '  cmd=$(printf "\\"%s\\" " "$@")'
				f.puts "  sudo -u #{git_user} -i eval \"ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i ${GIT_MIRROR_IDENTITY_FILE} $cmd\""
			end
			f.puts 'fi'
		end

		File.chmod(0550, git_exec_path())
		File.chmod(0550, gitolite_ssh_path())
		File.chmod(0550, git_user_runner_path())
		File.chmod(0550, git_exec_mirror_path())

		RepositoryMirror.find(:all, :order => 'active DESC, created_at ASC', :conditions => "active=1").each {|mirror|
			git_mirror_identity_file(mirror)
		}
	end

	def self.clone_or_pull_gitolite_admin
		# clone/pull from admin repo
		local_dir = get_tmp_dir()
		if File.exists? "#{local_dir}/gitolite-admin"
			logger.info "Fethcing changes for #{local_dir}/gitolite-admin"
			%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' fetch]
			%x[env GIT_SSH=#{gitolite_ssh()} git --git-dir='#{local_dir}/gitolite-admin/.git' --work-tree='#{local_dir}/gitolite-admin' merge FETCH_HEAD]
		else
			logger.info "Cloning gitolite-admin repository"
			%x[env GIT_SSH=#{gitolite_ssh()} git clone #{git_user}@#{Setting.plugin_redmine_git_hosting['gitServer']}:gitolite-admin.git #{local_dir}/gitolite-admin]
		end
		%x[chmod 700 "#{local_dir}/gitolite-admin" ]
		# Make sure we have out hooks setup
		Hooks::GitAdapterHooks.check_hooks_installed
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

		# Make sure we have gitoite-admin cloned
		clone_or_pull_gitolite_admin

		# rename in conf file
		conf = GitoliteConfig.new(File.join(local_dir, 'gitolite-admin', 'conf', 'gitolite.conf'))
		conf.rename_repo( old_name, new_name )
		conf.save

		# physicaly move the repo BEFORE committing/pushing conf changes to gitolite admin repo
		%x[#{git_user_runner} 'mkdir -p "#{new_path}"']
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

		logger.debug "Updating repositories..."
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

			# Make sure we have gitoite-admin cloned
			clone_or_pull_gitolite_admin


			conf = GitoliteConfig.new(File.join(local_dir, 'gitolite-admin', 'conf', 'gitolite.conf'))
			orig_repos = conf.all_repos
			new_repos = []
			new_projects = []
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
						new_projects.push project

						# Make sure the repository has a git_hook key instance
						if project.repository.hook_key.nil?
							project.repository.hook_key = GitHookKey.new
						end
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
					if (project.repository.extra.git_daemon == 1 || project.repository.extra.git_daemon == nil )  && project.is_public
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

			# Set post recieve hooks for new projects
			# We need to do this AFTER push, otherwise necessary repos may not be created yet
			if new_projects.length > 0
				GitHosting::Hooks::GitAdapterHooks.setup_hooks(new_projects)
			end

			lockfile.flock(File::LOCK_UN)
		end
		@recursionCheck = false

	end


	def self.clear_cache_for_project(project)
		if project.is_a?(Project)
			project = project.identifier
		end
		# Clear cache
		old_cached=GitCache.find_all_by_proj_identifier(project)
		if old_cached != nil
			old_ids = old_cached.collect(&:id)
			GitCache.destroy(old_ids)
		end
	end


	def self.run_post_receive_hook proj_identifier
		# Clear the cache
		clear_cache_for_project proj_identifier
		#fetch updates into repo
		Repository.fetch_changesets_for_project(proj_identifier)
	end

end

