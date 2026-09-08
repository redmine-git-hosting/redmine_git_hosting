# frozen_string_literal: true

require 'grack/auth'
require 'grack/server'

module RedmineGitHosting
  module Patches
    module GrackAuthPatch
      def call(env)
        @env = env
        @request = Rack::Request.new env
        @auth = Rack::Auth::Basic::Request.new env

        # Need this patch due to the rails mount

        # Need this if under RELATIVE_URL_ROOT
        # unless Gitlab.config.gitlab.relative_url_root.empty?
        #   # If website is mounted using relative_url_root need to remove it first
        #   @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root,'')
        # else
        #   @env['PATH_INFO'] = @request.path
        # end
	    
        path = @request.path_info
        return [400] unless m = /((?:[^\/]+\/)*?[^\/]+\.git)(\/.*)$/.match(path).to_a  
        @repo_path = m[1]
        @req_route = m[2]
          
        return render_not_found("Repository not found") unless repository
        return render_not_found("invalid route") unless has_route

        auth!
      end

      private
      def has_route
        Grack::Server::SERVICES.each do |method, _, match|
          next unless m = Regexp.new(match).match(@req_route)
          return method.include? @request.request_method
        end
        false
      end

      def auth!
        if @auth.provided?
          return bad_request unless @auth.basic?

          # Authentication with username and password
          login, password = @auth.credentials
          @user = authenticate_user login, password

          @env['REMOTE_USER'] = @user.gitolite_identifier if @user
        end

        if authorized_request?
          @app.call @env
        else
          unauthorized
        end
      end

      def authenticate_user(login, password)
        auth = RedmineGitHosting::Auth.new
        auth.find login, password
      end

      def authorized_request?
        case git_method
        when :pull
          if @user
            RedmineGitHosting::GitAccess.new.download_access_check(@user, repository, ssl: is_ssl?).allowed?
          else
            # Allow clone/fetch for public projects
            repository.public_project? || repository.public_repo?
          end
        when :push
          # Push requires valid SSL
          if !is_ssl?
            logger.error 'SmartHttp : your are trying to push data without SSL!, exiting !'
            false
          elsif @user
            RedmineGitHosting::GitAccess.new.upload_access_check(@user, repository).allowed?
          else
            false
          end
        else
          false
        end
      end
	  
      def git_cmd
        if @request.get?
          @request.params['service']
        elsif @request.post?
          File.basename @request.path
        else
          nil
        end
      end
      
      def git_method
	arr = @req_route.split('/', 5)[1...] # first item is empty string
	return git_lfs_cmd(arr) if arr[0] == "info" && arr[1] == "lfs"
        
	    case git_cmd
        when *RedmineGitHosting::GitAccess::DOWNLOAD_COMMANDS
          return :pull
        when *RedmineGitHosting::GitAccess::PUSH_COMMANDS
          return :push
        end
        
        return nil
      end

      def git_lfs_cmd(arr)
        case arr[2]
        when "objects" 
	        case @request.request_method
          when "POST" # batch request
            return :pull if arr[3] == "batch"
          when "GET"
            return :pull # file download
          when "PUT"
            return :push # file upload
          end
        when "locks"
	        if @request.get?
		        return :pull
	        elsif @request.post?
		        return :push if arr[3] == nil || arr[3] == "verify" || arr[4] == "unlock"
	        end
        end
        return nil
      end

      def repository
        @repository ||= Repository::Xitolite.find_by_path @repo_path, loose: true
      end

      def is_ssl?
        @request.ssl? || https_headers? || x_forwarded_proto_headers? || x_forwarded_ssl_headers?
      end

      def https_headers?
        @request.env['HTTPS'].to_s == 'on'
      end

      def x_forwarded_proto_headers?
        @request.env['HTTP_X_FORWARDED_PROTO'].to_s == 'https'
      end

      def x_forwarded_ssl_headers?
        @request.env['HTTP_X_FORWARDED_SSL'].to_s == 'on'
      end

      def render_not_found(msg = 'Not Found')
        [404, { 'Content-Type' => 'text/plain' }, [msg]]
      end

      def logger
        RedmineGitHosting.logger
      end
    end
  end
end

unless Grack::Auth.included_modules.include? RedmineGitHosting::Patches::GrackAuthPatch
  Grack::Auth.prepend RedmineGitHosting::Patches::GrackAuthPatch
end
