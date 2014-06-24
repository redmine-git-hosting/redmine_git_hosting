class RepositoryGitConfigKeysController < RedmineGitHostingController
  unloadable

  before_filter :set_current_tab
  before_filter :can_view_config_keys,   :only => [:index]
  before_filter :can_create_config_keys, :only => [:new, :create]
  before_filter :can_edit_config_keys,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_git_config_key, :except => [:index, :new, :create]


  def index
    @repository_git_config_keys = RepositoryGitConfigKey.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def new
    @git_config_key = RepositoryGitConfigKey.new()
  end


  def create
    @git_config_key = RepositoryGitConfigKey.new(params[:repository_git_config_key])
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


  def update
    respond_to do |format|
      if @git_config_key.update_attributes(params[:repository_git_config_key])
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


  private


  def can_view_config_keys
    render_403 unless view_context.user_allowed_to(:view_repository_git_config_keys, @project)
  end


  def can_create_config_keys
    render_403 unless view_context.user_allowed_to(:create_repository_git_config_keys, @project)
  end


  def can_edit_config_keys
    render_403 unless view_context.user_allowed_to(:edit_repository_git_config_keys, @project)
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


  def set_current_tab
    @tab = 'repository_git_config_keys'
  end

end
