require 'lockfile'
require 'inifile'
require 'net/ssh'
require 'tmpdir'
require 'gitolite/gitolite_config'

module Gitolite
  def self.renderReadOnlyUrls(baseUrlStr, projectId,parent)
    rendered = ""
    if (baseUrlStr.length == 0)
      return rendered
    end
    
    baseUrlList = baseUrlStr.split("%p")
    if (not defined?(baseUrlList.length))
      return rendered
    end
    
    rendered = rendered + "<strong>Read Only Url:</strong><br />"
    rendered = rendered + "<ul>"
    
    rendered = rendered + "<li>" + baseUrlList[0] +(parent ? "" : "/"+parent+"/")+ projectId + baseUrlList[1] + "</li>"
    
    rendered = rendered + "</ul>\n"
    
    return rendered
  end
  
	def self.renderUrls(baseUrlStr, projectId, isReadOnly, parent)
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
						rendered = rendered + "<li>" + "<span style=\"width: 95%; font-size:10px\">" + baseUrl+ (parent ? "" : "/"+parent+"/") + projectId + ".git</span></li>"
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

			# clone repo
			%x[git clone #{Setting.plugin_redmine_gitolite['gitoliteUrl']} #{local_dir}/gitolite]


			changed = false
			projects.select{|p| p.repository.is_a?(Repository::Git)}.each do |project|
				# fetch users
				users = project.member_principals.map(&:user).compact.uniq
				write_users = users.select{ |user| user.allowed_to?( :commit_access, project ) }
				read_users = users.select{ |user| user.allowed_to?( :view_changesets, project ) && !user.allowed_to?( :commit_access, project ) }
				# write key files
				users.map{|u| u.gitolite_public_keys.active}.flatten.compact.uniq.each do |key|
					File.open(File.join(local_dir, 'gitolite/keydir',"#{key.identifier}.pub"), 'w') {|f| f.write(key.key.gsub(/\n/,'')) }
				end

				# delete inactives
				users.map{|u| u.gitolite_public_keys.inactive}.flatten.compact.uniq.each do |key|
					File.unlink(File.join(local_dir, 'gitolite/keydir',"#{key.identifier}.pub")) rescue nil
				end

				# write config file
				conf = GitoliteConfig.new(File.join(local_dir,'gitolite','conf','gitolite.conf'))
				original = conf.clone
				name = "#{project.identifier}"

				conf.add_users name, :r, read_users.map{|u| u.gitolite_public_keys.active}.flatten.map{ |key| "#{key.identifier}" }

        # TODO: we should handle two different groups for this
				# conf.add_users name, :rw, read_users.map{|u| u.gitolite_public_keys.active}.flatten.map{ |key| "#{key.identifier}" }
				conf.add_users name, :rwp, write_users.map{|u| u.gitolite_public_keys.active}.flatten.map{ |key| "#{key.identifier}" }

        # TODO: gitweb and git daemon support!

				unless conf.eql?(original)
					conf.write 
					changed = true
				end

			end
			if changed
				git_push_file = File.join(local_dir, 'git_push.sh')

        # Changed to unix-style
        # TODO: platform independent code
	      new_dir= File.join(local_dir,'gitolite')
				File.open(git_push_file, "w") do |f|
					f.puts "cd #{new_dir}"
					f.puts "git add keydir/* gitolite.conf"
					f.puts "git config user.email '#{Setting.mail_from}'"
					f.puts "git config user.name 'Redmine'"
					f.puts "git commit -a -m 'updated by Redmine Gitolite'"
					f.puts "git push"
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
	
end
