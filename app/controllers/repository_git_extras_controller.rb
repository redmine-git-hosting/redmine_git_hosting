class RepositoryGitExtrasController < RedmineGitHostingController
  unloadable

  skip_before_filter :set_current_tab
  before_filter      :set_git_extra

  helper :extend_repositories


  def update
    if @git_extra.default_branch != params[:repository_git_extra][:default_branch]
      update_default_branch = true
    else
      update_default_branch = false
    end

    ## Update attributes
    if @git_extra.update_attributes(params[:repository_git_extra])
      flash.now[:notice] = l(:notice_gitolite_extra_updated)
      UpdateRepository.new(@repository, {update_default_branch: update_default_branch}).call
    else
      flash.now[:error] = l(:notice_gitolite_extra_update_failed)
    end
  end


  private


    def set_git_extra
      @git_extra = @repository.extra
    end

end
