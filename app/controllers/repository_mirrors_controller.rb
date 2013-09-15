class RepositoryMirrorsController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_user_variable
  before_filter :set_repository_variable
  before_filter :set_project_variable
  before_filter :check_required_permissions
  before_filter :check_xhr_request
  before_filter :find_repository_mirror, :except => [:index, :create]

  layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }

  def index
    render_404
  end

  def create
    @mirror = RepositoryMirror.new(params[:repository_mirrors])
    if request.get?
      # display create view
    else
      @mirror.update_attributes(params[:repository_mirrors])
      @mirror.repository = @repository

      if @mirror.save
        flash[:notice] = l(:notice_mirror_created)

        respond_to do |format|
          format.html { redirect_to success_url }
          format.js { render "update", :layout => false }
        end
      else
        respond_to do |format|
          format.html {
            flash[:error] = l(:notice_mirror_create_failed)
            render :action => "create"
          }
          format.js { render "form_error", :layout => false }
        end
      end
    end
  end

  def edit
  end

  def update
    if @mirror.update_attributes(params[:repository_mirrors])
      flash[:notice] = l(:notice_mirror_updated)

      respond_to do |format|
        format.html { redirect_to success_url }
        format.js { render "update", :layout => false }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = l(:notice_mirror_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end

  def destroy
    if request.get?
      # display confirmation view
    else
      if params[:confirm]
        @mirror.destroy
        flash[:notice] = l(:notice_mirror_deleted)
      end

      respond_to do |format|
        format.html { redirect_to success_url }
        format.js { render "destroy_done", :layout => false }
      end
    end
  end

  def push
    respond_to do |format|
      format.html { (@push_failed, @shellout) = @mirror.push }
    end
  end

  protected

  # This is a success URL to return to basic listing
  def success_url
    if GitHosting.multi_repos?
      url_for(:controller => 'repositories', :action => 'edit', :id => @repository.id)
    else
      url_for(:controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'repository')
    end
  end

  def set_user_variable
    @user = User.current
  end

  def set_repository_variable
    @repository = Repository.find_by_id(params[:repository_id])
    if !@repository
      render_404
    end
  end

  def set_project_variable
    @project = @repository.project
    if !@project
      render_404
    end
  end

  def find_repository_mirror
    mirror = RepositoryMirror.find_by_id(params[:id])
    if mirror and mirror.repository_id == @repository.id
      @mirror = mirror
    elsif mirror
      render_403
    else
      render_404
    end
  end

  def check_required_permissions
    # Deny access if the current user is not allowed to manage the project's repository
    if not @project.module_enabled?(:repository)
      render_403
    end
    return true if @user.admin?
    not_enough_perms = true
    @user.roles_for_project(@project).each{|role|
      if role.allowed_to? :manage_repository
        not_enough_perms = false
        break
      end
    }
    if not_enough_perms
      render_403
    end
  end

  def check_xhr_request
    @is_xhr ||= request.xhr?
  end

end
