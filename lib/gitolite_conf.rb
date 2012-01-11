module GitHosting
	class GitoliteConfig
        	DUMMY_REDMINE_KEY="redmine_dummy_key"

		def initialize file_path
			@path = file_path
			load
		end

        	def logger
			return GitHosting.logger
		end

		def save
			File.open(@path, "w") do |f|
				f.puts content
			end
			@original_content = content
		end

		def add_write_user repo_name, users
			repository(repo_name).add "RW+", users
		end

		def set_write_user repo_name, users
			repository(repo_name).set "RW+", users
		end

		def add_read_user repo_name, users
			repository(repo_name).add "R", users
		end

		def set_read_user repo_name, users
			repository(repo_name).set "R", users
		end

		def delete_repo repo_name
			@repositories.delete(repo_name)
		end

		def rename_repo old_name, new_name
			if @repositories.has_key?(old_name)
				perms = @repositories.delete(old_name)
				@repositories[new_name] = perms
			end
		end

                # A repository is a "redmine" repository if it has redmine keys or no keys 
                # (latter case is checked, since we end up adding the DUMMY_REDMINE_KEY to
                # a repository with no keys anyway....
                def is_redmine_repo? repo_name
                	repository(repo_name).rights.detect {|perm, users| users.detect {|key| is_redmine_key? key}} || (repo_has_no_keys? repo_name)
                end

                def delete_redmine_keys repo_name
			return if !@repositories[repo_name]
                
                	repository(repo_name).rights.each do |perm, users|
                		users.delete_if {|key| is_redmine_key? key}
                        end
                end
		
		def repo_has_no_keys? repo_name
                	!repository(repo_name).rights.detect {|perm, users| users.length > 0}
                end

                def is_redmine_key? keyname
                	(GitolitePublicKey::ident_to_user_token(keyname) || keyname == DUMMY_REDMINE_KEY) ? true : false
                end

		def changed?
			@original_content != content
		end

		def all_repos
			repos={}
			@repositories.each do |repo, rights|
				repos[repo] = 1
			end
			return repos
		end

                # For redmine repos, return map of basename (unique for redmine repos) => repo path
                def redmine_repo_map
                	redmine_repos=Hash.new{|hash, key| hash[key] = []}  # default -- empty list
                	@repositories.each do |repo, rights|
                    		if is_redmine_repo? repo
                                	# Represents bug in conf file, but must allow more than one
                                	mybase = File.basename(repo)
               				redmine_repos[mybase] << repo
                                end
                    	end
                  	return redmine_repos
                end

                def self.gitolite_repository_map
                	gitolite_repos=Hash.new{|hash, key| hash[key] = []}  # default -- empty list
                	myfiles = %x[#{GitHosting.git_user_runner} 'find #{GitHosting.repository_base} -type d -name "*.git" -prune -print'].chomp.split("\n")
                	filesplit = /(\.\/)*#{GitHosting.repository_base}(.*?)([^\/]+)\.git/
                	myfiles.each do |nextfile|
                		if filesplit =~ nextfile
                                	gitolite_repos[$3] << "#{$2}#{$3}"
                		end
               		end
                	gitolite_repos
                end

		private
		def load
			@original_content = []
			@repositories = ActiveSupport::OrderedHash.new
			cur_repo_name = nil
			File.open(@path).each_line do |line|
				@original_content << line
				tokens = line.strip.split
				if tokens.first == 'repo'
					cur_repo_name = tokens.last
					@repositories[cur_repo_name] = GitoliteAccessRights.new
					next
				end
				cur_repo_right = @repositories[cur_repo_name]
				if cur_repo_right and tokens[1] == '='
					cur_repo_right.add tokens.first, tokens[2..-1]
				end
			end
			@original_content = @original_content.join
		end

		def repository repo_name
			@repositories[repo_name] ||= GitoliteAccessRights.new
		end


		def content
			content = []

                  	# If no gitolite-admin user, something seriously wrong.  Add it in with id_rsa.
			#
                  	# If this doesn't work for some reason, will be corrected at later time by
                  	# gl-setup run.
                  	if @repositories["gitolite-admin"].nil?
                        	content << "repo\tgitolite-admin"
                          	content << "tRW+\t=\tid_rsa"
				content << ""
                        end
			@repositories.each do |repo, rights|
				content << "repo\t#{repo}"
				has_users=false
				rights.each do |perm, users|
					if users.length > 0
						has_users=true
						content << "\t#{perm}\t=\t#{users.join(' ')}"
					end
				end
				if !has_users
					# If no users, use dummy key to make sure repo created
                                	content << "\tR\t=\t#{DUMMY_REDMINE_KEY}"
				end
				content << ""
			end
			return content.join("\n")
		end

	end

	class GitoliteAccessRights
		def initialize
			@rights = ActiveSupport::OrderedHash.new
		end

		def rights
			@rights
		end

		def add perm, users
			@rights[perm.to_sym] ||= []
			@rights[perm.to_sym] << users
			@rights[perm.to_sym].flatten!
			@rights[perm.to_sym].uniq!
		end

		def set perm, users
			@rights[perm.to_sym] = []
			add perm, users
		end

		def each
			@rights.each {|k,v| yield k, v}
		end
	end
end

