class RepositoryGitConfigKeysController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository_variable
  before_filter :set_project_variable
  before_filter :check_required_permissions
  before_filter :check_xhr_request
  before_filter :find_repository_git_config_key, :except => [:index, :new, :create]

  layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }

  include GitHostingHelper
  helper  :git_hosting


  def index
    @repository_git_config_keys = RepositoryGitConfigKey.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def show
    render_404
  end


  def new
    @git_config_key = RepositoryGitConfigKey.new()
  end


  def create
    @git_config_key = RepositoryGitConfigKey.new(params[:repository_git_config_keys])
    @git_config_key.repository = @repository

    respond_to do |format|
      if @git_config_key.save
        flash[:notice] = l(:notice_git_config_key_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_git_config_key_create_failed)
          render :action => "create"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def edit
  end


  def update
    respond_to do |format|
      if @git_config_key.update_attributes(params[:repository_git_config_keys])
        flash[:notice] = l(:notice_git_config_key_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_git_config_key_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @git_config_key.destroy
        flash[:notice] = l(:notice_git_config_key_deleted)
        format.js { render :js => "window.location = #{success_url.to_json};" }
      else
        format.js { render :layout => false }
      end
    end
  end


  protected


  # This is a success URL to return to basic listing
  def success_url
    url_for(:controller => 'repositories', :action => 'edit', :id => @repository.id)
  end


  def set_repository_variable
    @repository = Repository.find_by_id(params[:repository_id])
    if @repository.nil?
      render_404
    end
  end


  def set_project_variable
    @project = @repository.project
    if @project.nil?
      render_404
    end
  end


  def find_repository_git_config_key
    git_config_key = RepositoryGitConfigKey.find_by_id(params[:id])

    if git_config_key && git_config_key.repository_id == @repository.id
      @git_config_key = git_config_key
    elsif git_config_key
      render_403
    else
      render_404
    end
  end


  def check_required_permissions
    # Deny access if the current user is not allowed to manage the project's repository
    if !@project.module_enabled?(:repository)
      render_403
    end

    return true if User.current.admin?

    not_enough_perms = true

    User.current.roles_for_project(@project).each do |role|
      if role.allowed_to?(:manage_repository)
        not_enough_perms = false
        break
      end
    end

    if not_enough_perms
      render_403
    end
  end


  def check_xhr_request
    @is_xhr ||= request.xhr?
  end

end
