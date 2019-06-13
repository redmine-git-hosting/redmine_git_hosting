class RepositoryMirrorsController < RedmineGitHostingController
  before_action :check_xitolite_permissions
  before_action :find_repository_mirror, except: %i[index new create]

  accept_api_auth :index, :show

  helper :additionals_clipboardjs

  def index
    @repository_mirrors = @repository.mirrors.all
    render_with_api
  end

  def new
    @mirror = @repository.mirrors.new
  end

  def create
    @mirror = @repository.mirrors.new
    @mirror.safe_attributes = params[:repository_mirror]
    return unless @mirror.save

    flash[:notice] = l(:notice_mirror_created)
    render_js_redirect
  end

  def update
    @mirror.safe_attributes = params[:repository_mirror]
    return unless @mirror.save

    flash[:notice] = l(:notice_mirror_updated)
    render_js_redirect
  end

  def destroy
    return unless @mirror.destroy

    flash[:notice] = l(:notice_mirror_deleted)
    render_js_redirect
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
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_xitolite_permissions
    if action_name == 'push'
      render_403 unless User.current.git_allowed_to?(:push_repository_mirrors, @repository)
    else
      super
    end
  end
end
