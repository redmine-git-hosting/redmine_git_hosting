class RepositoryDeploymentCredentialsController < RedmineGitHostingController
  unloadable

  before_filter :can_view_credentials,   :only => [:index]
  before_filter :can_create_credentials, :only => [:new, :create]
  before_filter :can_edit_credentials,   :only => [:edit, :update, :destroy]

  before_filter :find_deployment_credential, :only => [:edit, :update, :destroy]
  before_filter :find_key,                   :only => [:edit, :update, :destroy]
  before_filter :find_all_keys,              :only => [:index, :new, :create]

  helper :gitolite_public_keys


  def index
    @repository_deployment_credentials = @repository.deployment_credentials.all
    respond_to do |format|
      format.html { render layout: false }
    end
  end


  def new
    @credential = @repository.deployment_credentials.new()
  end


  def create
    @credential = @repository.deployment_credentials.new(params[:repository_deployment_credential])
    key = GitolitePublicKey.find_by_id(params[:repository_deployment_credential][:gitolite_public_key_id])

    @credential.gitolite_public_key = key if !key.nil?

    # If admin, let credential be owned by owner of key...
    if User.current.admin?
      @credential.user = key.user if !key.nil?
    else
      @credential.user = User.current
    end

    respond_to do |format|
      if @credential.save
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_deployment_credential_created)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js { render layout: false }
      end
    end
  end


  def update
    respond_to do |format|
      if @credential.update_attributes(params[:repository_deployment_credential])
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_deployment_credential_updated)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js { render layout: false }
      end
    end
  end


  def destroy
    will_delete_key = @key.deploy_key? && @key.delete_when_unused && @key.repository_deployment_credentials.count == 1

    @credential.destroy

    if will_delete_key && @key.repository_deployment_credentials.empty?
      # Key no longer used -- delete it!
      @key.destroy
      flash[:notice] = l(:notice_deployment_credential_deleted_with_key)
    else
      flash[:notice] = l(:notice_deployment_credential_deleted)
    end

    # Update Gitolite repository
    call_use_case

    respond_to do |format|
      format.js { render js: "window.location = #{success_url.to_json};" }
    end
  end


  private


    def set_current_tab
      @tab = 'repository_deployment_credentials'
    end


    def can_view_credentials
      render_403 unless view_context.user_allowed_to(:view_deployment_keys, @project)
    end


    def can_create_credentials
      render_403 unless view_context.user_allowed_to(:create_deployment_keys, @project)
    end


    def can_edit_credentials
      render_403 unless view_context.user_allowed_to(:edit_deployment_keys, @project)
    end


    def find_deployment_credential
      begin
        credential = @repository.deployment_credentials.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render_404
      else
        if credential.user && (User.current.admin? || credential.user == User.current)
          @credential = credential
        else
          render_403
        end
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
      @user_keys = User.current.gitolite_public_keys.deploy_key.order('title ASC')
      @disabled_keys = @repository.deployment_credentials.map(&:gitolite_public_key)

      @other_keys = []
      if User.current.admin?
        # Admin can use other's deploy keys as well
        deploy_users = @project.users.select {|x| x != User.current && x.allowed_to?(:create_deployment_keys, @project)}
        @other_keys  = deploy_users.map {|user| user.gitolite_public_keys.deploy_key.order('title ASC')}.flatten
      end
    end


    def call_use_case
      options = { message: "Update deploy keys for repository : '#{@repository.gitolite_repository_name}'" }
      UpdateRepository.new(@repository, options).call
    end

end
