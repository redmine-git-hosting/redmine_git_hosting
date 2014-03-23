class RepositoryMirrorsController < RedmineGitHostingController
  unloadable

  before_filter :can_view_mirrors,   :only => [:index]
  before_filter :can_create_mirrors, :only => [:new, :create]
  before_filter :can_edit_mirrors,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_mirror, :except => [:index, :new, :create]


  def index
    @repository_mirrors = RepositoryMirror.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def new
    @mirror = RepositoryMirror.new()
  end


  def create
    @mirror = RepositoryMirror.new(params[:repository_mirrors])
    @mirror.repository = @repository

    respond_to do |format|
      if @mirror.save
        flash[:notice] = l(:notice_mirror_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_mirror_create_failed)
          render :action => "create"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def update
    respond_to do |format|
      if @mirror.update_attributes(params[:repository_mirrors])
        flash[:notice] = l(:notice_mirror_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_mirror_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @mirror.destroy
        flash[:notice] = l(:notice_mirror_deleted)
        format.js { render :js => "window.location = #{success_url.to_json};" }
      else
        format.js { render :layout => false }
      end
    end
  end


  def push
    respond_to do |format|
      format.html { (@push_failed, @shellout) = @mirror.push }
    end
  end


  private


  def can_view_mirrors
    render_403 unless view_context.user_allowed_to(:view_repository_mirrors, @project)
  end


  def can_create_mirrors
    render_403 unless view_context.user_allowed_to(:create_repository_mirrors, @project)
  end


  def can_edit_mirrors
    render_403 unless view_context.user_allowed_to(:edit_repository_mirrors, @project)
  end


  def find_repository_mirror
    mirror = RepositoryMirror.find_by_id(params[:id])

    if mirror && mirror.repository_id == @repository.id
      @mirror = mirror
    elsif mirror
      render_403
    else
      render_404
    end
  end


end
