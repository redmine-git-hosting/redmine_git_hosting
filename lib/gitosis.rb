require 'lockfile'
require 'inifile'
require 'net/ssh'
require 'tmpdir'

module Gitosis
  def self.renderReadOnlyUrls(baseUrlStr, projectId)
    rendered = ""
    if (baseUrlStr.length == 0)
      return rendered
    end
    
    baseUrlList = baseUrlStr.split(/[%p]+/)
    if (not defined?(baseUrlList.length))
      return rendered
    end
    
    rendered = rendered + "<strong>Read Only Url:</strong><br />\n"
    rendered = rendered + "<ul>"
    
    rendered = rendered + "<li>"
    projectName = projectId
    if (baseUrlList.length > 1)
	    rendered = rendered + baseUrlList[0] + projectName + baseUrlList[1]
    else
	    rendered = rendered + baseUrlList[0] + projectName
    end
    rendered = rendered + "</li>\n"
    
    rendered = rendered + "</ul>\n"
    
    return rendered
  end
  
	def self.renderUrls(baseUrlStr, projectId, isReadOnly)
		rendered = ""
		if(baseUrlStr.length == 0)
			return rendered
		end
		baseUrlList=baseUrlStr.split(/[\r\n\t ,;]+/)

		if(not defined?(baseUrlList.length))
			return rendered
		end


		rendered = rendered + "<strong>" + (isReadOnly ? "Read Only" : "Developer") + " " + (baseUrlList.length == 1 ? "URL" : "URLs") + ": </strong><br/>"
				rendered = rendered + "<ul>";
				for baseUrl in baseUrlList do
						rendered = rendered + "<li>" + "<span style=\"width: 95%; font-size:10px\">" + baseUrl + projectId + ".git</span></li>"
				end
		rendered = rendered + "</ul>\n"
		return rendered
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

			lockfile=File.new(File.join(RAILS_ROOT,"tmp",'redmine_gitosis_lock'),File::CREAT|File::RDONLY)
			retries=5
			loop do
				break if lockfile.flock(File::LOCK_EX|File::LOCK_NB)
				retries-=1
				sleep 2
				raise Lockfile::MaxTriesLockError if retries<=0
			end


			# HANDLE GIT

			# create tmp dir
			local_dir = File.join(RAILS_ROOT,"tmp","redmine_gitosis_#{Time.now.to_i}")

			Dir.mkdir local_dir

			# clone repo
			`git clone #{Setting.plugin_redmine_gitosis['gitosisUrl']} #{local_dir}/gitosis`

			projects.select{|p| p.repository.is_a?(Repository::Git)}.each do |project|
				# fetch users
				users = project.member_principals.map(&:user).compact.uniq
				write_users = users.select{ |user| user.allowed_to?( :commit_access, project ) }
				read_users = users.select{ |user| user.allowed_to?( :view_changesets, project ) && !user.allowed_to?( :commit_access, project ) }
				# write key files
				users.map{|u| u.gitosis_public_keys.active}.flatten.compact.uniq.each do |key|
					File.open(File.join(local_dir, 'gitosis/keydir',"#{key.identifier}.pub"), 'w') {|f| f.write(key.key.gsub(/\n/,'')) }
				end

				# delete inactives
				users.map{|u| u.gitosis_public_keys.inactive}.flatten.compact.uniq.each do |key|
					File.unlink(File.join(local_dir, 'gitosis/keydir',"#{key.identifier}.pub")) rescue nil
				end

				# write config file
				conf = IniFile.new(File.join(local_dir,'gitosis','gitosis.conf'))
				original = conf.clone
				name = "#{project.identifier}"

				conf["group #{name}_readonly"]['readonly'] = name
				conf["group #{name}_readonly"]['members'] = read_users.map{|u| u.gitosis_public_keys.active}.flatten.map{ |key| "#{key.identifier}" }.join(' ')

				conf["group #{name}"]['writable'] = name
				conf["group #{name}"]['members'] = write_users.map{|u| u.gitosis_public_keys.active}.flatten.map{ |key| "#{key.identifier}" }.join(' ')

				# git-daemon support for read-only anonymous access
				if Setting.plugin_redmine_gitosis['enableGitdaemon'] and
						User.anonymous.allowed_to?( :view_changesets, project )
					conf["repo #{name}"]['daemon'] = 'yes'
				else
					conf["repo #{name}"]['daemon'] = 'no'
				end
				# Enable/disable gitweb
				if Setting.plugin_redmine_gitosis['enableGitweb'] and
						User.anonymous.allowed_to?( :view_changesets, project )
					conf["repo #{name}"]['gitweb'] = 'yes'
				else
					conf["repo #{name}"]['gitweb'] = 'no'
				end
				conf["repo #{name}"]['description'] = project.name

				unless conf.eql?(original)
					conf.write 
				end

			end
			git_push_file = File.join(local_dir, 'git_push.bat')

			new_dir= File.join(local_dir,'gitosis')
			File.open(git_push_file, "w") do |f|
				f.puts "#!/bin/sh" if not mswin?
				f.puts "cd #{new_dir}"
				f.puts "git add keydir/* gitosis.conf"
				f.puts "git config user.email '#{Setting.mail_from}'"
				f.puts "git config user.name 'Redmine'"
				f.puts "git commit -a -m 'updated by Redmine Gitosis'"
				f.puts "git push"
			end
			File.chmod(0755, git_push_file)

			# add, commit, push, and remove local tmp dir
			if (Setting.plugin_redmine_gitosis['gitosisLogFile'] != nil) and
					(Setting.plugin_redmine_gitosis['gitosisLogFile'].length > 0)
				`#{git_push_file} >> #{Setting.plugin_redmine_gitosis['gitosisLogFile']}`
			else
				`#{git_push_file}`
			end
			# remove local copy
			`rm -Rf #{local_dir}`

			lockfile.flock(File::LOCK_UN)
		end
		@recursionCheck = false

	end

	def self.mswin?  # copy & paste from redmine/extra/svn/reposman.rb:mswin?
		(RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
	end

end
