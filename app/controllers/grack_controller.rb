require 'zlib'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'time'

class GrackController < ApplicationController

	def index
		render :text=>"<html><body>p1=" + params[:p1] + "<br>p2=" + params[:p2] + "<br>p3=" + params[:p3] + "</body></body>\n"
	end

	def service_rpc
		return render_no_access if !has_access(@rpc, true)
		input = read_body

		@res = Rack::Response.new
		@res.status = 200
		@res["Content-Type"] = "application/x-git-%s-result" % @rpc
		@res.finish do
			command = git_command("#{@rpc} --stateless-rpc #{@dir}")
			IO.popen(command, File::RDWR) do |pipe|
				pipe.write(input)
				while !pipe.eof?
					block = pipe.read(8192) # 8M at a time
					@res.write block				# steam it to the client
				end
			end
		end
	end

	def get_info_refs
		service_name = get_service_type

		if has_access(service_name)
			cmd = git_command("#{service_name} --stateless-rpc --advertise-refs .")
			refs = `#{cmd}`

			@res = Rack::Response.new
			@res.status = 200
			@res["Content-Type"] = "application/x-git-%s-advertisement" % service_name
			hdr_nocache
			@res.write(pkt_write("# service=git-#{service_name}\n"))
			@res.write(pkt_flush)
			@res.write(refs)
			@res.finish
		else
			dumb_info_refs
		end
	end

	def dumb_info_refs
		update_server_info
		grack_send_file(@reqfile, "text/plain; charset=utf-8") do
			hdr_nocache
		end
	end

	def get_info_packs
		# objects/info/packs
		grack_send_file(@reqfile, "text/plain; charset=utf-8") do
			hdr_nocache
		end
	end

	def get_loose_object
		grack_send_file(@reqfile, "application/x-git-loose-object") do
			hdr_cache_forever
		end
	end

	def get_pack_file
		grack_send_file(@reqfile, "application/x-git-packed-objects") do
			hdr_cache_forever
		end
	end

	def get_idx_file
		grack_send_file(@reqfile, "application/x-git-packed-objects-toc") do
			hdr_cache_forever
		end
	end

	def get_text_file
		grack_send_file(@reqfile, "text/plain") do
			hdr_nocache
		end
	end

	# ------------------------
	# logic helping functions
	# ------------------------

	F = ::File

	# some of this borrowed from the Rack::File implementation
	def grack_send_file(reqfile, content_type)
		reqfile = File.join(@dir, reqfile)
		return render_not_found if !F.exists?(reqfile)

		send_file(reqfile,  :type=>content_type, :disposition=>"inline", :buffer_size => 4096)
	end

	def get_git_dir(path)
		root = @config[:project_root] || `pwd`
		path = File.join(root, path)
		if File.exists?(path) # TODO: check is a valid git directory
			return path
		end
		false
	end

	def get_service_type
		service_type = @req.params['service']
		return false if !service_type
		return false if service_type[0, 4] != 'git-'
		service_type.gsub('git-', '')
	end


	def has_access(rpc, check_content_type = false)
		return true
		if check_content_type
			return false if @req.content_type != "application/x-git-%s-request" % rpc
		end
		return false if !['upload-pack', 'receive-pack'].include? rpc
		if rpc == 'receive-pack'
			return @config[:receive_pack] if @config.include? :receive_pack
		end
		if rpc == 'upload-pack'
			return @config[:upload_pack] if @config.include? :upload_pack
		end
		return get_config_setting(rpc)
	end

	def get_config_setting(service_name)
		service_name = service_name.gsub('-', '')
		setting = get_git_config("http.#{service_name}")
		if service_name == 'uploadpack'
			return setting != 'false'
		else
			return setting == 'true'
		end
	end

	def get_git_config(config_name)
		cmd = git_command("config #{config_name}")
		`#{cmd}`.chomp
	end

	def read_body
		if @env["HTTP_CONTENT_ENCODING"] =~ /gzip/
			input = Zlib::GzipReader.new(@req.body).read
		else
			input = @req.body.read
		end
	end

	def update_server_info
		cmd = git_command("update-server-info")
		`#{cmd}`
	end

	def git_command(command)
		git_bin = 'git'
		command = "#{git_bin} #{command}"
		command
	end

	# --------------------------------------
	# HTTP error response handling functions
	# --------------------------------------

	def render_method_not_allowed
		if @env['SERVER_PROTOCOL'] == "HTTP/1.1"
			head :method_not_allowed
		else
			head :bad_request
		end
	end

	def render_not_found
		head :not_found
	end

	def render_no_access
		head :forbidden
	end


	# ------------------------------
	# packet-line handling functions
	# ------------------------------

	def pkt_flush
		'0000'
	end

	def pkt_write(str)
		(str.size + 4).to_s(base=16).rjust(4, '0') + str
	end


	# ------------------------
	# header writing functions
	# ------------------------

	def hdr_nocache
		response.headers["Expires"] = "Fri, 01 Jan 1980 00:00:00 GMT"
		response.headers["Pragma"] = "no-cache"
		response.headers["Cache-Control"] = "no-cache, max-age=0, must-revalidate"
	end

	def hdr_cache_forever
		now = Time.now().to_i
		response.headers["Date"] = now.to_s
		response.headers["Expires"] = (now + 31536000).to_s;
		response.headers["Cache-Control"] = "public, max-age=31536000";
	end
end
