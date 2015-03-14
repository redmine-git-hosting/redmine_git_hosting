class RepositoryGitNotificationsController < RedmineGitHostingController
  unloadable

  before_filter :check_xitolite_permissions

  helper :tag_it


  def index
    render_404
  end


  def show
    @git_notification = @repository.git_notification
    render layout: false
  end


  def new
    @git_notification = @repository.build_git_notification
  end


  def create
    @git_notification = @repository.build_git_notification(params[:repository_git_notification])
    if @git_notification.save
      flash[:notice] = l(:notice_git_notifications_created)
      call_use_case_and_redirect
    end
  end


  def edit
    @git_notification = @repository.git_notification
  end


  def update
    @git_notification = @repository.git_notification
    if @git_notification.update_attributes(params[:repository_git_notification])
      flash[:notice] = l(:notice_git_notifications_updated)
      call_use_case_and_redirect
    end
  end


  def destroy
    @git_notification = @repository.git_notification
    if @git_notification.destroy
      flash[:notice] = l(:notice_git_notifications_deleted)
      call_use_case_and_redirect
    end
  end


  private


    def set_current_tab
      @tab = 'repository_git_notifications'
    end


    def call_use_case
      options = { message: "Rebuild mailing list for respository : '#{@repository.gitolite_repository_name}'" }
      GitoliteAccessor.update_repository(@repository, options)
    end

end
