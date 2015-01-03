class GoRedirectorController < ApplicationController
  unloadable

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :verify_authenticity_token

  before_filter :find_repository


  def index
  end


  private


    def find_repository
      repository = Repository::Xitolite.find_by_path(repo_path, loose: true)
      if repository.nil?
        logger.error("GoRedirector : repository not found at path : '#{repo_path}', exiting !")
        render_404
      elsif !repository.smart_http_enabled?
        logger.error("GoRedirector : SmartHttp is disabled for this repository '#{repository.gitolite_repository_name}', exiting !")
        render_403
      else
        @repository = repository
      end
    end


    def repo_path
      params[:repo_path] + '.git'
    end


    def logger
      RedmineGitHosting.logger
    end

end
