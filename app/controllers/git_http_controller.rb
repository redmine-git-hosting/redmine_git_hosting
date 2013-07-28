require 'zlib'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'time'

class GitHttpController < ApplicationController

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :verify_authenticity_token

  before_filter :authenticate

  def index

    @request = Rack::Request.new(request.env)

    command, @git_repo_path, @requested_file, @rpc = match_routing

    return render_method_not_allowed if command == 'not_allowed'
    return render_not_found if !command

    # strip HTTP prefix
    @git_repo_path = @git_repo_path.sub(params[:prefix], '')

    logger.info "###### AUTHENTICATED ######"
    logger.info "project name   : #{@project.identifier}"
    logger.info "repository dir : #{@repository.url}"
    logger.info "repository path: #{@git_repo_path}"
    logger.info "is_push        : #{@is_push}"
    if !@user.nil?
      logger.info "user_name      : #{@user.login}"
    else
      logger.info "user_name      : anonymous (project is public)"
    end
    logger.info "command        : #{command}"
    logger.info "##########################"

    self.method(command).call()

  end

  private

  def authenticate
    # fixme: rails3 route blobbing will not convert *other to array
    params[:path] = params[:path].split("/")
    @is_push = (params[:path][0] == "git-receive-pack" || params[:service] == "git-receive-pack")

    query_valid = false
    authentication_valid = true

    logger.info "###### AUTHENTICATION ######"
    logger.info "param   : #{params[:path]}"
    logger.info "is_push : #{@is_push}"
    logger.info "############################"

    if (@repository = Repository.find_by_path(params[:repo_path],:parse_ext=>true)) && @repository.is_a?(Repository::Git)
      if (@project = @repository.project) && @repository.extra[:git_http] != 0
        allow_anonymous_read = @project.is_public
        # Push requires HTTP enabled or valid SSL
        # Read is ok over HTTP for public projects
        if @repository.extra[:git_http] == 2 || (@repository.extra[:git_http] == 1 && is_ssl?) || !@is_push && allow_anonymous_read
          query_valid = true
          if @is_push || (!allow_anonymous_read)
            authentication_valid = false
            authenticate_or_request_with_http_basic do |login, password|
              @user = User.find_by_login(login);
              if @user.is_a?(User)
                if @user.allowed_to?( :commit_access, @project ) || ((!@is_push) && @user.allowed_to?( :view_changesets, @project ))
                  authentication_valid = @user.check_password?(password)
                end
              end
              authentication_valid
            end
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


  def get_enumerator
    if RUBY_VERSION == '1.8.7'
      Enumerable::Enumerator
    else
      Enumerator
    end
  end


  def service_rpc
    input = read_body

    command = git_command("#{@rpc} --stateless-rpc .")

    logger.info "###### SERVICE RPC ######"
    logger.info "command    : #{command}"
    logger.debug "input data : #{input}"
    logger.info "#########################"

    self.response.headers["Content-Type"] = "application/x-git-%s-result" % @rpc
    self.response.status = 200

    if Rails::VERSION::MAJOR >= 3
      IO.popen(command, File::RDWR) do |pipe|
        pipe.write(input)
        while !pipe.eof?
          block = pipe.read()
          self.response_body = get_enumerator.new do |y|
            y << block.to_s
          end
        end
      end
    else
      @git_http_control_pipe = IO.popen(command, File::RDWR)
      @git_http_control_pipe.write(input)

      render :text => proc { |response, output|
        buf_length=131072
        buf = @git_http_control_pipe.read(buf_length)
        while(!(buf.nil?) && buf.length == buf_length)
          output.write( buf )
          buf = @git_http_control_pipe.read(buf_length)
        end
        if(!(buf.nil?) && buf.length > 0)
          output.write( buf )
        end
        @git_http_control_pipe.close
        @git_http_control_pipe = nil
      }
    end
  end


  def get_info_refs
    service_name = get_service_type

    if service_name
      command = git_command("#{service_name} --stateless-rpc --advertise-refs .")
      refs = %x[#{command}]
      content_type = "application/x-git-#{service_name}-advertisement"

      logger.info "###### GET INFO REFS ######"
      logger.info "command      : #{command}"
      logger.info "refs         : #{refs}"
      logger.info "content_type : #{content_type}"
      logger.info "service_name : #{service_name}"
      logger.info "###########################"

      self.response.status = 200
      self.response.headers["Content-Type"] = content_type
      hdr_nocache

      if Rails::VERSION::MAJOR >= 3
        self.response_body = get_enumerator.new do |y|
          y << pkt_write("# service=git-#{service_name}\n")
          y << pkt_flush
          y << refs
        end
      else
        response_data = pkt_write("# service=git-#{service_name}\n") + pkt_flush + refs
        render :text=>response_data
      end

    else
      dumb_info_refs
    end
  end


  def dumb_info_refs
    update_server_info
    internal_send_file(@requested_file,  "text/plain; charset=utf-8") do
      hdr_nocache
    end
  end


  def get_info_packs
    # objects/info/packs
    internal_send_file(@requested_file,  "text/plain; charset=utf-8") do
      hdr_nocache
    end
  end


  def get_loose_object
    internal_send_file(@requested_file,  "application/x-git-loose-object") do
      hdr_cache_forever
    end
  end


  def get_pack_file
    internal_send_file(@requested_file, "application/x-git-packed-objects") do
      hdr_cache_forever
    end
  end


  def get_idx_file
    internal_send_file(@requested_file, "application/x-git-packed-objects-toc") do
      hdr_cache_forever
    end
  end


  def get_text_file
    internal_send_file(@requested_file, "text/plain") do
      hdr_nocache
    end
  end

  # ------------------------
  # logic helping functions
  # ------------------------

  SERVICES = [
    ["POST", 'service_rpc',      "/(.*?)/git-upload-pack$",  'upload-pack'],
    ["POST", 'service_rpc',      "/(.*?)/git-receive-pack$", 'receive-pack'],

    ["GET",  'get_info_refs',    "/(.*?)/info/refs$"],
    ["GET",  'get_text_file',    "/(.*?)/HEAD$"],
    ["GET",  'get_text_file',    "/(.*?)/objects/info/alternates$"],
    ["GET",  'get_text_file',    "/(.*?)/objects/info/http-alternates$"],
    ["GET",  'get_info_packs',   "/(.*?)/objects/info/packs$"],
    ["GET",  'get_text_file',    "/(.*?)/objects/info/[^/]*$"],
    ["GET",  'get_loose_object', "/(.*?)/objects/[0-9a-f]{2}/[0-9a-f]{38}$"],
    ["GET",  'get_pack_file',    "/(.*?)/objects/pack/pack-[0-9a-f]{40}\\.pack$"],
    ["GET",  'get_idx_file',     "/(.*?)/objects/pack/pack-[0-9a-f]{40}\\.idx$"],
  ]

  def match_routing
    cmd = nil
    path = nil
    SERVICES.each do |method, handler, match, rpc|
      if m = Regexp.new(match).match(@request.path_info)
        return ['not_allowed'] if method != @request.request_method
        cmd = handler
        path = m[1]
        file = @request.path_info.sub(path + '/', '')

        logger.info "######## ROUTING #########"
        logger.info "path      : #{path}"
        logger.info "path info : #{@request.path_info}"
        logger.info "file      : #{file}"
        logger.info "rpc       : #{rpc}"
        logger.info "##########################"

        return [cmd, path, file, rpc]
      end
    end
    return nil
  end


  # some of this borrowed from the Rack::File implementation
  def internal_send_file(requested_file, content_type)

    return render_not_found if !File.exists?(requested_file)

    last_modified = File.mtime(requested_file).httpdate
    file_size = File.size?(requested_file)

    logger.info "###### SEND FILE ######"
    logger.info "requested_file : #{requested_file}"
    logger.info "content_type   : #{content_type}"
    logger.info "last_modified  : #{last_modified}"
    logger.info "file_size      : #{file_size}"
    logger.info "#######################"


    if Rails::VERSION::MAJOR >= 3
      self.response.status = 200
      self.response.headers["Last-Modified"] = last_modified
      self.response.headers["Content-Length"] = file_size.to_s
      #~ cache_parameter

      send_file requested_file, :type => content_type

    else
      self.response.headers["Content-Type"] = content_type
      command = "#{run_git_prefix()} dd if=#{requested_file} '"
      @git_http_control_pipe = IO.popen(command, File::RDWR)
      render :text => proc { |response, output|
        buf_length=131072
        buf = @git_http_control_pipe.read(buf_length)
        while(!(buf.nil?) && buf.length == buf_length)
          output.write( buf )
          buf = @git_http_control_pipe.read(buf_length)
        end
        if(!(buf.nil?) && buf.length > 0)
          output.write( buf )
        end
        @git_http_control_pipe.close
        @git_http_control_pipe = nil
      }
    end
  end


  def file_exists(requested_file)
    command = "#{run_git_prefix()} if [ -e \"#{requested_file}\" ] ; then echo found ; else echo bad ; fi ' "
    is_found = %x[#{command}]
    is_found.chomp!
    return is_found == "found"
  end


  #note command needs to be terminated with a quote!
  def run_git_prefix
    return "#{GitHosting::git_user_runner()} 'cd #{GitHostingConf.repository_base}#{@git_repo_path} ; "
  end


  def is_ssl?
    return request.ssl? || (request.env['HTTPS']).to_s == 'on' || (request.env['HTTP_X_FORWARDED_PROTO']).to_s == 'https' || (request.env['HTTP_X_FORWARDED_SSL']).to_s == 'on'
  end


  def read_body
    enc_header = (request.headers['HTTP_CONTENT_ENCODING']).to_s
    if enc_header =~ /gzip/
      input = Zlib::GzipReader.new(request.body).read
    else
      input = request.body.read
    end
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
    command = git_command("config #{config_name}")
    %x[#{command}].chomp
  end


  def update_server_info
    command = git_command("update-server-info")
    %x[#{command}]
  end


  def git_command(command)
    return "#{run_git_prefix()} env GL_BYPASS_UPDATE_HOOK=true git #{command} '"
  end

  # --------------------------------------
  # HTTP error response handling functions
  # --------------------------------------

  def render_method_not_allowed
    logger.info "###### HTTP ERRORS ######"
    if request.env['SERVER_PROTOCOL'] == "HTTP/1.1"
      logger.info "method : not allowed"
      head :method_not_allowed
    else
      logger.info "method : bad request"
      head :bad_request
    end
    logger.info "#########################"
    return head
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
    self.response.headers["Expires"] = "Fri, 01 Jan 1980 00:00:00 GMT"
    self.response.headers["Pragma"] = "no-cache"
    self.response.headers["Cache-Control"] = "no-cache, max-age=0, must-revalidate"
  end

  def hdr_cache_forever
    now = Time.now().to_i
    self.response.headers["Date"] = now.to_s
    self.response.headers["Expires"] = (now + 31536000).to_s;
    self.response.headers["Cache-Control"] = "public, max-age=31536000";
  end

  def logger
    Rails.logger
  end

end
