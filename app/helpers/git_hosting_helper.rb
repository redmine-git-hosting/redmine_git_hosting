
module GitHostingHelper

	def self.git_daemon_enabled(repository, value)
		gd = 1
		if repository && !repository.extra.nil?
			gd = repository.extra[:git_daemon] ? repository.extra[:git_daemon] : gd
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
		if repository && !repository.extra.nil?
			gh = repository.extra[:git_http] ? repository.extra[:git_http] : gh
		end
		if gh == value
			return "selected='selected'"
		else
			return ""
		end
	end

end
