class RepositoryGitExtrasController < RedmineGitHostingController
  include RedmineGitHosting::GitoliteAccessor::Methods

  skip_before_action :set_current_tab

  helper :extend_repositories

  def update
    @git_extra = @repository.extra
    @git_extra.safe_attributes = params[:repository_git_extra]

    if @git_extra.save
      flash.now[:notice] = l(:notice_gitolite_extra_updated)
      gitolite_accessor.update_repository(@repository, update_default_branch: @git_extra.default_branch_has_changed?)
    else
      flash.now[:error] = l(:notice_gitolite_extra_update_failed)
    end
  end

  def sort_urls
    @git_extra = @repository.extra
    return unless request.post?

    if @git_extra.update(urls_order: params[:repository_git_extra])
      flash.now[:notice] = l(:notice_gitolite_extra_updated)
    else
      flash.now[:error] = l(:notice_gitolite_extra_update_failed)
    end
  end

  def move
    @move_repository_form = MoveRepositoryForm.new(@repository)
    return unless request.post?

    @move_repository_form = MoveRepositoryForm.new(@repository)

    return unless @move_repository_form.submit(params[:repository_mover])

    redirect_to settings_project_path(@repository.project, tab: 'repositories')
  end

  private

  def set_git_extra
    @git_extra = @repository.extra
  end
end
