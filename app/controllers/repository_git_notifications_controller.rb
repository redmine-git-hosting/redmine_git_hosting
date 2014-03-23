class RepositoryGitNotificationsController < RedmineGitHostingController
  unloadable

  before_filter :set_current_tab
  before_filter :can_view_git_notifications,   :only => [:index]
  before_filter :can_create_git_notifications, :only => [:new, :create]
  before_filter :can_edit_git_notifications,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_git_notification, :except => [:index, :new, :create]


  def index
    @git_notification = RepositoryGitNotification.find_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def new
    @git_notification = RepositoryGitNotification.new()
  end


  def create
    params[:repository_git_notifications][:include_list] = params[:repository_git_notifications][:include_list].select{|mail| !mail.blank?}
    params[:repository_git_notifications][:exclude_list] = params[:repository_git_notifications][:exclude_list].select{|mail| !mail.blank?}

    @git_notification = RepositoryGitNotification.new(params[:repository_git_notifications])
    @git_notification.repository = @repository

    respond_to do |format|
      if @git_notification.save
        flash[:notice] = l(:notice_git_notifications_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_git_notifications_create_failed)
          render :action => "create"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def update
    params[:repository_git_notifications][:include_list] = params[:repository_git_notifications][:include_list].select{|mail| !mail.blank?}
    params[:repository_git_notifications][:exclude_list] = params[:repository_git_notifications][:exclude_list].select{|mail| !mail.blank?}

    respond_to do |format|
      if @git_notification.update_attributes(params[:repository_git_notifications])
        flash[:notice] = l(:notice_git_notifications_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_git_notifications_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @git_notification.destroy
        flash[:notice] = l(:notice_git_notifications_deleted)
        format.js { render :js => "window.location = #{success_url.to_json};" }
      else
        format.js { render :layout => false }
      end
    end
  end


  private


  def can_view_git_notifications
    render_403 unless view_context.user_allowed_to(:view_repository_git_notifications, @project)
  end


  def can_create_git_notifications
    render_403 unless view_context.user_allowed_to(:create_repository_git_notifications, @project)
  end


  def can_edit_git_notifications
    render_403 unless view_context.user_allowed_to(:edit_repository_git_notifications, @project)
  end


  def find_repository_git_notification
    git_notification = RepositoryGitNotification.find_by_id(params[:id])

    if git_notification && git_notification.repository_id == @repository.id
      @git_notification = git_notification
    elsif git_notification
      render_403
    else
      render_404
    end
  end


  def set_current_tab
    @tab = 'repository_git_notifications'
  end

end
