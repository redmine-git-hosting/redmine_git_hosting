class RepositoryPostReceiveUrlsController < RedmineGitHostingController

  before_filter :check_xitolite_permissions
  before_filter :find_repository_post_receive_url, except: [:index, :new, :create]

  accept_api_auth :index, :show


  def index
    @repository_post_receive_urls = @repository.post_receive_urls.all
    render_with_api
  end


  def new
    @post_receive_url = @repository.post_receive_urls.new
  end


  def create
    @post_receive_url = @repository.post_receive_urls.new(params[:repository_post_receive_url])
    if @post_receive_url.save
      flash[:notice] = l(:notice_post_receive_url_created)
      render_js_redirect
    end
  end


  def update
    if @post_receive_url.update_attributes(params[:repository_post_receive_url])
      flash[:notice] = l(:notice_post_receive_url_updated)
      render_js_redirect
    end
  end


  def destroy
    if @post_receive_url.destroy
      flash[:notice] = l(:notice_post_receive_url_deleted)
      render_js_redirect
    end
  end


  private


    def set_current_tab
      @tab = 'repository_post_receive_urls'
    end


    def find_repository_post_receive_url
      @post_receive_url = @repository.post_receive_urls.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end

end
