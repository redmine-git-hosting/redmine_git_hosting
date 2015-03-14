class RepositoryGitConfigKeysController < RedmineGitHostingController
  unloadable

  before_filter :check_xitolite_permissions
  before_filter :find_repository_git_config_key, except: [:index, :new, :create]

  accept_api_auth :index, :show


  def index
    @repository_git_config_keys = @repository.git_config_keys.all
    render_with_api
  end


  def new
    @git_config_key = @repository.git_config_keys.new
  end


  def create
    @git_config_key = @repository.git_config_keys.new(params[:repository_git_config_key])
    if @git_config_key.save
      flash[:notice] = l(:notice_git_config_key_created)
      call_use_case_and_redirect
    end
  end


  def update
    if @git_config_key.update_attributes(params[:repository_git_config_key])
      flash[:notice] = l(:notice_git_config_key_updated)
      call_use_case_and_redirect
    end
  end


  def destroy
    if @git_config_key.destroy
      flash[:notice] = l(:notice_git_config_key_deleted)
      call_use_case_and_redirect
    end
  end


  private


    def set_current_tab
      @tab = 'repository_git_config_keys'
    end


    def find_repository_git_config_key
      @git_config_key = @repository.git_config_keys.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end


    def call_use_case
      case self.action_name
      when 'create'
        options = {}
      when 'update'
        options = @git_config_key.key_has_changed? ? { delete_git_config_key: @git_config_key.old_key } : {}
      when 'destroy'
        options = { delete_git_config_key: @git_config_key.key }
      end
      options = options.merge(message: "Rebuild Git config keys respository : '#{@repository.gitolite_repository_name}'")
      GitoliteAccessor.update_repository(@repository, options)
    end

end
