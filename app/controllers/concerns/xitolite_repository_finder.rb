module XitoliteRepositoryFinder
  extend ActiveSupport::Concern

  def find_xitolite_repository
    begin
      @repository = Repository::Xitolite.find(find_repository_param)
    rescue ActiveRecord::RecordNotFound => e
      render_404
    else
      @project = @repository.project
      render_404 if @project.nil?
    end
  end


  def find_xitolite_repository_by_path
    repo_path = params[:repo_path] + '.git'
    repository = Repository::Xitolite.find_by_path(repo_path, loose: true)
    if repository.nil?
      RedmineGitHosting.logger.error("GoRedirector : repository not found at path : '#{repo_path}', exiting !")
      render_404
    elsif !repository.go_access_available?
      RedmineGitHosting.logger.error("GoRedirector : GoAccess is disabled for this repository '#{repository.gitolite_repository_name}', exiting !")
      render_403
    else
      RedmineGitHosting.logger.info("GoRedirector : access granted for repository '#{repository.gitolite_repository_name}'")
      @repository = repository
    end
  end

end
