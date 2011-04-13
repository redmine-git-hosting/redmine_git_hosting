class GitRepoHostingOptions < ActiveRecord::Base

	belongs_to :repository

	def self.find_for_repo(repo)
		gitOps = nil
		if repo
			if repo.is_a?(Repository::Git)
				gitOpList = self.find(:all, :conditions=>{:repository_id=>repo.id})
				if(gitOpList.length == 0)
					gitOps = GitRepoHostingOptions.new do |g|
						g.repository_id=repo[:id]
					end	
				else
					gitOps = gitOpList[0]	
				end
			end
		end
		return gitOps
	end

	def to_s
		self.repository_id.to_s
	end  
end
