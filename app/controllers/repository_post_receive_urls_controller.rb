class RepositoryPostReceiveUrlsController < RedmineGitHostingController
  before_action :check_xitolite_permissions
  before_action :find_repository_post_receive_url, except: %i[index new create]

  accept_api_auth :index, :show

  def index
    @repository_post_receive_urls = @repository.post_receive_urls.all
    render_with_api
  end

  def new
    @post_receive_url = @repository.post_receive_urls.new
  end

  def create
    @post_receive_url = @repository.post_receive_urls.new
    @post_receive_url.safe_attributes = params[:repository_post_receive_url]
    return unless @post_receive_url.save

    flash[:notice] = l(:notice_post_receive_url_created)
    render_js_redirect
  end

  def update
    @post_receive_url.safe_attributes = params[:repository_post_receive_url]
    return unless @post_receive_url.save

    flash[:notice] = l(:notice_post_receive_url_updated)
    render_js_redirect
  end

  def destroy
    return unless @post_receive_url.destroy

    flash[:notice] = l(:notice_post_receive_url_deleted)
    render_js_redirect
  end

  private

  def set_current_tab
    @tab = 'repository_post_receive_urls'
  end

  def find_repository_post_receive_url
    @post_receive_url = @repository.post_receive_urls.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
