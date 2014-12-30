module Grack
  class Auth < Rack::Auth::Basic

    attr_accessor :user, :project, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

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

          if @user
            @env['REMOTE_USER'] = @auth.username
          end
        end

        if authorized_request?
          @app.call(env)
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
          if user
            RedmineGitHosting::GitAccess.new.download_access_check(user, repository).allowed?
          elsif repository.public_project?
            # Allow clone/fetch for public projects
            true
          else
            false
          end
        when *RedmineGitHosting::GitAccess::PUSH_COMMANDS
          if user
            # Skip user authorization on upload request.
            # It will be done by the pre-receive hook in the repository.
            RedmineGitHosting::GitAccess.new.upload_access_check(user, repository).allowed?
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


      def render_not_found
        [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
      end

  end
end
