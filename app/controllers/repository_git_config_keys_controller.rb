class RepositoryGitConfigKeysController < RedmineGitHostingController
  unloadable

  before_filter :can_view_config_keys,   :only => [:index]
  before_filter :can_create_config_keys, :only => [:new, :create]
  before_filter :can_edit_config_keys,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_git_config_key, :except => [:index, :new, :create]


  def index
    @repository_git_config_keys = @repository.git_config_keys.all
    render layout: false
  end


  def new
    @git_config_key = @repository.git_config_keys.new
  end


  def create
    @git_config_key = @repository.git_config_keys.new(params[:repository_git_config_key])
    respond_to do |format|
      if @git_config_key.save
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_config_key_created)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js
      end
    end
  end


  def update
    respond_to do |format|
      if @git_config_key.update_attributes(params[:repository_git_config_key])
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_config_key_updated)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js
      end
    end
  end


  def destroy
    respond_to do |format|
      if @git_config_key.destroy
        # Update Gitolite repository
        call_use_case

        flash[:notice] = l(:notice_git_config_key_deleted)
        format.js { render js: "window.location = #{success_url.to_json};" }
      end
    end
  end


  private


    def set_current_tab
      @tab = 'repository_git_config_keys'
    end


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
      @git_config_key = @repository.git_config_keys.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end


    def call_use_case
      options = {}
      case self.action_name
      when 'update'
        options = { delete_git_config_key: @git_config_key.old_key } if @git_config_key.key_has_changed?
      when 'destroy'
        options = { delete_git_config_key: @git_config_key.key }
      end
      options = options.merge(message: "Rebuild Git config keys respository : '#{@repository.gitolite_repository_name}'")
      GitoliteAccessor.update_repository(@repository, options)
    end

end
