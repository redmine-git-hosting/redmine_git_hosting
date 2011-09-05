
require 'rack/response'
require 'rack/utils'
require 'time'

class GitHttpController < ApplicationController

	before_filter :authenticate


	def index
		p1 = params[:p1]
		p2 = params[:p2]
		p3 = params[:p3]
		proj_id = params[:id]
		
		
		@git_http_repo_path = (params[:path]).gsub(/\.git$/, "")
		
		reqfile = p2 == "" ? p1 : ( p3 == "" ? p1 + "/" + p2 : p1 + "/" + p2 + "/" + p3);

		if p1 == "git-upload-pack"
			service_rpc("upload-pack")
		elsif p1 == "git-receive-pack"
			service_rpc("receive-pack")
		elsif p1 == "info" && p2 == "refs"
			get_info_refs(reqfile)
		elsif p1 == "HEAD"
			get_text_file(reqfile)
		elsif p1 == "objects" && p2 == "info"
			if p3 != packs
				get_text_file(reqfile)
			else
				get_info_packs(reqfile)
			end
		elsif p1 == "objects" && p2 != "pack"
			get_loose_object(reqfile)
		elsif p1 == "objects" && p2 == "pack" && p3.match(/\.pack$/)
			get_pack_file(reqfile)
		elsif p1 == "objects" && p2 == "pack" && p3.match(/\.idx$/)
			get_idx_file(reqfile)
		else
			render_not_found
		end

	end

	private

	def authenticate
		is_push = params[:p1] == "git-receive-pack"	
		query_valid = false
		authentication_valid = true
		
		project = Project.find(params[:id])
		repository = project != nil ? project.repository : nil
		if(project != nil && repository !=nil) 
			if repository.extra[:git_http] == 2 || (repository.extra[:git_http] == 1 && is_ssl?)
				query_valid = true
				allow_anonymous_read = project.is_public	
				if is_push || (!allow_anonymous_read)
					authentication_valid = false
					authenticate_or_request_with_http_basic do |login, password| 
						user = User.find_by_login(login);
						if user.is_a?(User)
							if user.allowed_to?( :commit_access, project ) || ((!is_push) && user.allowed_to?( :view_changesets, project ))
								authentication_valid = user.check_password?(password)
							end
						end
						authentication_valid
					end
				end
			end
		end

		#if authentication failed, error already rendered
		#so, just render case where user queried a project 
		#that's nonexistant or for which smart http isn't active
		if !query_valid
			render_not_found
		end

		return query_valid && authentication_valid
	end

	def service_rpc(rpc)
		input = read_body

		response.headers["Content-Type"] = "application/x-git-%s-result" % rpc
		command = git_command("#{rpc} --stateless-rpc .")
		@git_http_control_pipe = IO.popen(command, File::RDWR)
		@git_http_control_pipe.write(input)
	
		render :text => proc { |response, output| 
			buf_length=131072
			buf = @git_http_control_pipe.read(buf_length)
			while(buf.length == buf_length)
				output.write( buf )
				buf = @git_http_control_pipe.read(buf_length)
			end
			if(buf.length > 0)
				output.write( buf )
			end
			@git_http_control_pipe.close
			@git_http_control_pipe = nil
		}
	end

	def get_info_refs(reqfile)
		service_name = get_service_type
		if service_name 
			cmd = git_command("#{service_name} --stateless-rpc --advertise-refs .")
			refs = %x[#{cmd}]

			response.headers["Content-Type"] = "application/x-git-%s-advertisement" % service_name
			hdr_nocache
			
			response_data = pkt_write("# service=git-#{service_name}\n") + pkt_flush + refs
			render :text=>response_data
		else
			dumb_info_refs(reqfile)
		end
	end

	def dumb_info_refs(reqfile)
		update_server_info
		internal_send_file(reqfile,  "text/plain; charset=utf-8") do
			hdr_nocache
		end
	end

	def get_info_packs(reqfile)
		# objects/info/packs
		internal_send_file(reqfile,  "text/plain; charset=utf-8") do
			hdr_nocache
		end
	end

	def get_loose_object(reqfile)
		internal_send_file(reqfile,  "application/x-git-loose-object") do
			hdr_cache_forever
		end
	end

	def get_pack_file(reqfile)

		internal_send_file(reqfile, "application/x-git-packed-objects") do
			hdr_cache_forever
		end
	end

	def get_idx_file(reqfile)
		internal_send_file(reqfile, "application/x-git-packed-objects-toc") do
			hdr_cache_forever
		end
	end

	def get_text_file(reqfile)
		internal_send_file(reqfile, "text/plain") do
			hdr_nocache
		end
	end

	# ------------------------
	# logic helping functions
	# ------------------------

	# some of this borrowed from the Rack::File implementation
	def internal_send_file(reqfile, content_type)
		
		response.headers["Content-Type"] = content_type
		if !file_exists(reqfile)
			return render_not_found 
		else
			command = "#{run_git_prefix()} dd if=#{reqfile} '"
			@git_http_control_pipe = IO.popen(command, File::RDWR)
			render :text => proc { |response, output| 
				buf_length=131072
				buf = @git_http_control_pipe.read(buf_length)
				while(buf.length == buf_length)
					output.write( buf )
					buf = @git_http_control_pipe.read(buf_length)
				end
				if(buf.length > 0)
					output.write( buf )
				end
				@git_http_control_pipe.close
				@git_http_control_pipe = nil
			}
		end
	end

	def file_exists(reqfile)
		
		cmd="#{run_git_prefix()} if [ -e \"#{reqfile}\" ] ; then echo found ; else echo bad ; fi ' "
		is_found=%x[#{cmd}]
		is_found.chomp!
		return is_found == "found"
	end



	def get_service_type
		service_type = params[:service]
		return false if !service_type
		return false if service_type[0, 4] != 'git-'
		service_type.gsub('git-', '')
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
		%x[#{cmd}].chomp
	end

	def read_body
		enc_header = (request.headers['HTTP_CONTENT_ENCODING']).to_s
		if enc_header =~ /gzip/
			input = Zlib::GzipReader.new(request.body).read
		else
			input = request.body.read
		end
	end

	def update_server_info
		cmd = git_command("update-server-info")
		%x[#{cmd}]
	end

	def git_command(command)
		return "#{run_git_prefix()} env GL_BYPASS_UPDATE_HOOK=true git #{command} '"
	end

	
	#note command needs to be terminated with a quote!
	def run_git_prefix
		return "#{GitHosting::git_user_runner()} 'cd #{Setting.plugin_redmine_git_hosting['gitRepositoryBasePath']}/#{@git_http_repo_path}.git ; "
	end

	def is_ssl?
		return (request.env['HTTPS']).to_s == 'on' || (request.env['HTTP_X_FORWARDED_PROTO']).to_s == 'https' || (request.env['HTTP_X_FORWARDED_SSL']).to_s == 'on'
	end

	# --------------------------------------
	# HTTP error response handling functions
	# --------------------------------------

	def render_method_not_allowed
		if request.env['SERVER_PROTOCOL'] == "HTTP/1.1"
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
