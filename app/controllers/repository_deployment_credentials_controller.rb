class RepositoryDeploymentCredentialsController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository_variable
  before_filter :set_project_variable
  before_filter :check_xhr_request

  before_filter :can_create_credentials, :only => [:new, :create]
  before_filter :can_edit_credentials,   :only => [:edit, :update, :destroy]

  before_filter :find_deployment_credential, :only => [:edit, :update, :destroy]
  before_filter :find_key,                   :only => [:edit, :update, :destroy]
  before_filter :find_all_keys,              :only => [:index, :new]

  include GitHostingHelper
  include GitolitePublicKeysHelper

  helper :git_hosting
  helper :gitolite_public_keys

  layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }


  def index
    @repository_deployment_credentials = RepositoryDeploymentCredential.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def show
    render_404
  end


  def new
    @credential = RepositoryDeploymentCredential.new()
  end


  def create
    @credential = RepositoryDeploymentCredential.new(params[:repository_deployment_credentials])
    key = GitolitePublicKey.find_by_id(params[:repository_deployment_credentials][:gitolite_public_key_id])

    @credential.repository = @repository
    @credential.gitolite_public_key = key if !key.nil?

    # If admin, let credential be owned by owner of key...
    if User.current.admin?
      @credential.user = key.user if !key.nil?
    else
      @credential.user = User.current
    end

    respond_to do |format|
      if @credential.save
        flash[:notice] = l(:notice_deployment_credential_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:error_deployment_credential_create_failed)
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
      if @credential.update_attributes(params[:repository_deployment_credentials])
        flash[:notice] = l(:notice_deployment_credential_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:error_deployment_credential_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    will_delete_key = @key.deploy_key? && @key.delete_when_unused && @key.repository_deployment_credentials.count == 1

    @credential.destroy

    if will_delete_key && @key.repository_deployment_credentials.empty?
      # Key no longer used -- delete it!
      delete_ssh_key
      @key.destroy
      flash[:notice] = l(:notice_deployment_credential_deleted_with_key)
    else
      flash[:notice] = l(:notice_deployment_credential_deleted)
    end

    respond_to do |format|
      format.js { render :js => "window.location = #{success_url.to_json};" }
    end
  end


  protected


  def delete_ssh_key
    repo_key = {}
    repo_key[:title]    = @key.identifier
    repo_key[:key]      = @key.key
    repo_key[:location] = @key.location
    repo_key[:owner]    = @key.owner
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :delete_ssh_key, :object => repo_key })
  end


  # This is a success URL to return to basic listing
  def success_url
    url_for(:controller => 'repositories', :action => 'edit', :id => @repository.id)
  end


  def can_view_credentials
    render_403 unless can_view_deployment_keys(@project)
  end


  def can_create_credentials
    render_403 unless can_create_deployment_keys(@project)
  end


  def can_edit_credentials
    render_403 unless can_edit_deployment_keys(@project)
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


  def find_deployment_credential
    credential = RepositoryDeploymentCredential.find_by_id(params[:id])

    if credential && credential.user && credential.repository && (User.current.admin? || credential.user == User.current)
      @credential = credential
    elsif credential
      render_403
    else
      render_404
    end
  end


  def find_key
    key = @credential.gitolite_public_key
    if key && key.user && (User.current.admin? || key.user == User.current)
      @key = key
    elsif key
      render_403
    else
      render_404
    end
  end


  def find_all_keys
    # display create_with_key view.  Find preexisting keys to offer to user
    @user_keys = GitolitePublicKey.by_user(User.current).active.deploy_key.order('title ASC')
    @disabled_keys = @repository.repository_deployment_credentials.active.map(&:gitolite_public_key)

    @other_keys = []
    if User.current.admin?
      # Admin can use other's deploy keys as well
      deploy_users = @project.users.find(:all, :order => "login ASC").select {|x| x != User.current && x.allowed_to?(:create_deployment_keys, @project)}
      @other_keys = deploy_users.map {|user| user.gitolite_public_keys.active.deploy_key.find(:all, :order => "title ASC")}.flatten
    end
  end


  def check_xhr_request
    @is_xhr ||= request.xhr?
  end

end
