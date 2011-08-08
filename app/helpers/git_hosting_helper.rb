
module GitHostingHelper

	def self.git_daemon_enabled(repository, value)
		gd = 1
		if repository
			gd = repository[:git_daemon] ? repository[:git_daemon] : gd
		end
		gd = repository.project.is_public ? gd : 0
		if gd == value
			return "selected='selected'"
		else
			return ""
		end
	end

	def self.git_http_enabled(repository, value)
		gh = 1
		if repository
			gh = repository[:git_http] ? repository[:git_http] : gh
		end
		if gh == value
			return "selected='selected'"
		else
			return ""
		end
	end

end
