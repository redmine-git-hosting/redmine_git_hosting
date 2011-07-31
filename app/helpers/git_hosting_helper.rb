require "uri"
require "net/http"

module GitHostingHelper

	@@file_actions = {
		"a" => "add",
		"m" => "modify",
		"r" => "remove",
		"d" => "remove"
	}

	@http_server = nil

	def url_for_revision(revision)
		rev = revision.respond_to?(:identifier) ? revision.identifier : revision
		shorten_url(
			url_for(:controller => 'repositories', :action => 'revision', :id => revision.project,
				:rev => rev, :only_path => false, :host => Setting['host_name'], :protocol => Setting['protocol']
			)
		)
	end

	def url_for_revision_path(revision, path)
		rev = revision.respond_to?(:identifier) ? revision.identifier : revision
		shorten_url(
			url_for(:controller => 'repositories', :action => 'entry', :id => revision.project,
				:rev => rev, :path => path, :only_path => false, :host => Setting['host_name'],
				:protocol => Setting['protocol']
			)
		)
	end

	def map_file_action(action)
		@@file_actions.fetch(action.downcase, action)
	end

	def shorten_url(url)
		if @http_server.nil?
			@uri = URI.parse("http://tinyurl.com/api-create.php")
			@http_server = Net::HTTP.new(@uri.host, @uri.port)
			@http_server.open_timeout = 1 # in seconds
			@http_server.read_timeout = 1 # in seconds
		end
		uri = @uri
		uri.query = "url=#{url}"
		request = Net::HTTP::Get.new(uri.request_uri)
		begin
			response = @http_server.request(request)
			GitHosting.logger.debug "Shortened URL is: #{response.body}"
			return response.body
		rescue Exception => e
			GitHosting.logger.warn "Failed to shorten url: #{e}"
			return url
		end
	end


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

	def self.notify_cia_enabled(project, value)
		if not project.repository
			return ""
		end
		nc = 0
		project.repository[:notify_cia] ? project.repository[:notify_cia] : nc
		if nc == value
			return "selected='selected'"
		else
			return ""
		end
	end
end
