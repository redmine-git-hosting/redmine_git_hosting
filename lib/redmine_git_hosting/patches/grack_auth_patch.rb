require 'grack/auth'

module RedmineGitHosting
  module Patches
    module GrackAuthPatch

      def call(env)
        @env = env
        @request = Rack::Request.new(env)
        @auth = Rack::Auth::Basic::Request.new(env)

        # Need this patch due to the rails mount

        # Need this if under RELATIVE_URL_ROOT
        # unless Gitlab.config.gitlab.relative_url_root.empty?
        #   # If website is mounted using relative_url_root need to remove it first
        #   @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root,'')
        # else
        #   @env['PATH_INFO'] = @request.path
        # end

        if repository
          auth!
        else
          render_not_found
        end
      end


      private


        def auth!
          if @auth.provided?
            return bad_request unless @auth.basic?

            # Authentication with username and password
            login, password = @auth.credentials
            @user = authenticate_user(login, password)

            @env['REMOTE_USER'] = @user.gitolite_identifier if @user
          end

          if authorized_request?
            @app.call(@env)
          else
            unauthorized
          end
        end


        def authenticate_user(login, password)
          auth = RedmineGitHosting::Auth.new
          auth.find(login, password)
        end


        def authorized_request?
          case git_cmd
          when *RedmineGitHosting::GitAccess::DOWNLOAD_COMMANDS
            if @user
              RedmineGitHosting::GitAccess.new.download_access_check(@user, repository, is_ssl?).allowed?
            elsif repository.public_project? || repository.public_repo?
              # Allow clone/fetch for public projects
              true
            else
              false
            end
          when *RedmineGitHosting::GitAccess::PUSH_COMMANDS
            # Push requires valid SSL
            if !is_ssl?
              logger.error('SmartHttp : your are trying to push data without SSL!, exiting !')
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
            File.basename(@request.path)
          else
            nil
          end
        end


        def repository
          @repository ||= repository_by_path(@request.path_info)
        end


        def repository_by_path(path)
          if m = /([^\/]+\/)*?[^\/]+\.git/.match(path).to_a
            repo_path = m.first
            Repository::Xitolite.find_by_path(repo_path, loose: true)
          end
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


        def render_not_found
          [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end


        def logger
          RedmineGitHosting.logger
        end

    end
  end
end

unless Grack::Auth.included_modules.include?(RedmineGitHosting::Patches::GrackAuthPatch)
  Grack::Auth.send(:prepend, RedmineGitHosting::Patches::GrackAuthPatch)
end
