
module GitHostingHelper

	def self.git_daemon_enabled(project, value)
		if not project.repository
			return ""
		end
		gd = 1
		project.repository[:git_daemon] ? project.repository[:git_daemon] : gd
		gd = project.is_public ? gd : 0
		if gd == value
			return "selected='selected'"
		else
			return ""
		end
	end

	def self.git_http_enabled(project, value)
		if not project.repository
			return ""
		end
		gh = 1
		project.repository[:git_http] ? project.repository[:git_http] : gh
		if gh == value
			return "selected='selected'"
		else
			return ""
		end
	end

end
