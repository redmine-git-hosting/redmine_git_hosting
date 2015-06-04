class RepositoryGitExtrasController < RedmineGitHostingController
  unloadable

  skip_before_filter :set_current_tab

  helper :extend_repositories


  def update
    @git_extra = @repository.extra
    ## Update attributes
    if @git_extra.update_attributes(params[:repository_git_extra])
      flash.now[:notice] = l(:notice_gitolite_extra_updated)
      GitoliteAccessor.update_repository(@repository, { update_default_branch: @git_extra.default_branch_has_changed? })
    else
      flash.now[:error] = l(:notice_gitolite_extra_update_failed)
    end
  end


  def sort_urls
    @git_extra = @repository.extra
    if request.post?
      if @git_extra.update_attributes(urls_order: params[:repository_git_extra])
        flash.now[:notice] = l(:notice_gitolite_extra_updated)
      else
        flash.now[:error] = l(:notice_gitolite_extra_update_failed)
      end
    end
  end


  def move
    @move_repository_form = MoveRepositoryForm.new(@repository)
    if request.post?
      @move_repository_form = MoveRepositoryForm.new(@repository)
      if @move_repository_form.submit(params[:repository_mover])
        redirect_to settings_project_path(@repository.project, tab: 'repositories')
      end
    end
  end


  private


    def set_git_extra
      @git_extra = @repository.extra
    end

end
