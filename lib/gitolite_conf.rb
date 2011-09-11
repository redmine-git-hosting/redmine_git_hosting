module GitHosting
	class GitoliteConfig
		def initialize file_path
			@path = file_path
			load
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

			# To facilitate creation of repos, even when no users are defined
			# always define at least one user -- specifically the admin
			# user which has rights to modify gitolite-admin and control
			# all repos.  Since the gitolite-admin user can grant anyone
			# any permission anyway, this isn't really a security risk.
			# If no users are defined, this ensures the repo actually
			# gets created, hence it's necessary.
			admin_user = @repositories["gitolite-admin"].rights["RW+".to_sym][0]
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
					content << "\tR\t=\t#{admin_user}"
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

