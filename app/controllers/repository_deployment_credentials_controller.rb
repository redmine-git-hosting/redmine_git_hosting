class RepositoryDeploymentCredentialsController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_user_variable
  before_filter :set_repository_variable
  before_filter :set_project_variable

  before_filter :can_create_credentials, :only => [:create, :create_with_key]
  before_filter :can_edit_credentials, :only => [:edit, :update, :destroy]

  before_filter :check_xhr_request
  before_filter :find_deployment_credential, :except => [:index, :new, :create, :create_with_key]
  before_filter :find_key, :except => [:index, :new, :create, :create_with_key]

  helper :gitolite_public_keys
  include GitolitePublicKeysHelper

  layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }


  def index
    render_404
  end


  def create
    render_404
  end


  def create_with_key
    @cred = RepositoryDeploymentCredential.new(params[:repository_deployment_credentials])
    @key = nil
    if params[:gitolite_public_key] && params[:gitolite_public_key][:id]
      @key = GitolitePublicKey.find_by_id(params[:gitolite_public_key][:id])
      if @key && !User.current.admin? && (@key.user != User.current)
        # Key not owned by current user -- cannot be used
        @key = nil
      end
    end

    @key = GitolitePublicKey.new(params[:gitolite_public_key]) if @key.nil?
    if request.get?
      # display create_with_key view.  Find preexisting keys to offer to user
      @user_keys = GitolitePublicKey.active.deploy_key.find_all_by_user_id(User.current.id, :order => "title ASC")
      @other_keys = []
      if User.current.admin?
        # Admin can use other's deploy keys as well
        deploy_users = @project.users.find(:all, :order => "login ASC").select {|x| x != User.current && x.allowed_to?(:create_deployment_keys, @project)}
        @other_keys = deploy_users.map {|user| user.gitolite_public_keys.active.deploy_key.find(:all, :order => "title ASC")}.flatten
      end
      @disabled_keys = @repository.repository_deployment_credentials.active.map(&:gitolite_public_key)
      if @key.new_record?
        @key.title = suggested_title
      end
    else
      if @key.new_record?
        @key.key_type = GitolitePublicKey::KEY_TYPE_DEPLOY
        @key.user = User.current
      elsif @key.key_type != GitolitePublicKey::KEY_TYPE_DEPLOY
        # Should never happen through normal interface...
        render_403
        return
      end
      @cred.repository = @repository
      # If admin, let credential be owned by owner of key...
      if User.current.admin?
        @cred.user = @key.user
      else
        @cred.user = User.current
      end

      # Make sure that cred will validate even if key is new.
      @cred.gitolite_public_key = @key

      GitHostingObserver.set_update_active(false)

      @key.valid?  # set error messages on key (in case cred is invalid)
      if @cred.valid? && @key.save && @cred.save
        flash[:notice] = l(:notice_deployment_credential_added, :title => keylabel(@key), :perm => @cred[:perm])

        respond_to do |format|
          format.html { redirect_to success_url }
          format.js { render "update", :layout => false }
        end
      else
        respond_to do |format|
          format.html {
            flash[:error] = l(:error_deployment_credential_create_failed)
            render :action => "create_with_key"
          }
          format.js { render "form_error", :layout => false }
        end
      end

      GitHostingObserver.set_update_active(@project)
    end
  end


  def edit
    # Credential should already be set.
  end


  def update
    GitHostingObserver.set_update_active(false)

    # Can only alter the permissions
    if @cred.update_attributes(params[:repository_deployment_credentials])
      flash[:notice] = l(:notice_deployment_credential_updated, :title => keylabel(@key), :perm => @cred[:perm])

      respond_to do |format|
        format.html { redirect_to success_url }
        format.js { render "update", :layout => false }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = l(:error_deployment_credential_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end

    GitHostingObserver.set_update_active(@project)
  end


  def destroy
    key = @cred.gitolite_public_key
    @will_delete_key = key.deploy_key? && key.delete_when_unused && key.repository_deployment_credentials.count == 1
    if request.get?
      # display confirmation view
    else
      GitHostingObserver.set_update_active(false)
      if params[:confirm]
        key = @cred.gitolite_public_key
        @cred.destroy
        if @will_delete_key && key.repository_deployment_credentials.empty?
          # Key no longer used -- delete it!
          #delete_ssh_key(key)
          key.destroy
          flash[:notice] = l(:notice_deployment_credential_deleted_with_key, :title => keylabel(@key), :perm => @cred[:perm])
        else
          flash[:notice] = l(:notice_deployment_credential_deleted, :title => keylabel(@key), :perm => @cred[:perm])
        end
      end

      respond_to do |format|
        format.html { redirect_to success_url }
        format.js { render "destroy_done", :layout => false }
      end

      GitHostingObserver.set_update_active(@project)
    end
  end


  protected


  def delete_ssh_key(key)
    repo_key = Hash.new
    repo_key[:title]    = key.identifier
    repo_key[:key]      = key.key
    repo_key[:location] = key.location
    repo_key[:owner]    = key.owner
    GitHosting.resync_gitolite({ :command => :delete_ssh_key, :object => repo_key })
  end


  # This is a success URL to return to basic listing
  def success_url
    if GitHosting.multi_repos?
      url_for(:controller => 'repositories', :action => 'edit', :id => @repository.id)
    else
      url_for(:controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'repository')
    end
  end


  def can_view_credentials
    render_403 unless GitHostingHelper.can_view_deployment_keys(@project)
  end


  def can_create_credentials
    render_403 unless GitHostingHelper.can_create_deployment_keys(@project)
  end


  def can_edit_credentials
    render_403 unless GitHostingHelper.can_edit_deployment_keys(@project)
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


  def find_deployment_credential
    cred = RepositoryDeploymentCredential.find_by_id(params[:id])
    if cred && cred.user && cred.repository && (User.current.admin? || cred.user == User.current)
      @cred = cred
    elsif cred
      render_403
    else
      render_404
    end
  end


  def find_key
    key = @cred.gitolite_public_key
    if key && key.user && (User.current.admin? || key.user == User.current)
      @key = key
    elsif key
      render_403
    else
      render_404
    end
  end


  # Suggest title for new one-of deployment key
  def suggested_title
    # Base of suggested title
    default_title = "#{@project.name} Deploy Key"

    # Find number of keys or max default deploy key that matches
    maxnum = @repository.repository_deployment_credentials.map(&:gitolite_public_key).uniq.count
    @repository.repository_deployment_credentials.each do |cred|
      if matches = cred.gitolite_public_key.title.match(/#{default_title} (\d+)$/)
        maxnum = [maxnum, matches[1].to_i].max
      end
    end

    # Also, check for uniqueness for current user
    @user.gitolite_public_keys.each do |key|
      if matches = key.title.match(/#{default_title} (\d+)$/)
        maxnum = [maxnum, matches[1].to_i].max
      end
    end

    "#{default_title} #{maxnum+1}"
  end


  def check_xhr_request
    @is_xhr ||= request.xhr?
  end

end
