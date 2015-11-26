class RepositoryMirrorsController < RedmineGitHostingController

  before_filter :check_xitolite_permissions
  before_filter :find_repository_mirror, except: [:index, :new, :create]

  accept_api_auth :index, :show


  def index
    @repository_mirrors = @repository.mirrors.all
    render_with_api
  end


  def new
    @mirror = @repository.mirrors.new
  end


  def create
    @mirror = @repository.mirrors.new(params[:repository_mirror])
    if @mirror.save
      flash[:notice] = l(:notice_mirror_created)
      render_js_redirect
    end
  end


  def update
    if @mirror.update_attributes(params[:repository_mirror])
      flash[:notice] = l(:notice_mirror_updated)
      render_js_redirect
    end
  end


  def destroy
    if @mirror.destroy
      flash[:notice] = l(:notice_mirror_deleted)
      render_js_redirect
    end
  end


  def push
    @push_failed, @shellout = RepositoryMirrors::Push.call(@mirror)
    render layout: false
  end


  private


    def set_current_tab
      @tab = 'repository_mirrors'
    end


    def find_repository_mirror
      @mirror = @repository.mirrors.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end


    def check_xitolite_permissions
      if self.action_name == 'push'
        render_403 unless User.current.git_allowed_to?(:push_repository_mirrors, @repository)
      else
        super
      end
    end

end
