class RepositoryPostReceiveUrlsController < RedmineGitHostingController
  unloadable

  before_filter :find_repository_post_receive_url, :except => [:index, :new, :create]


  def index
    @repository_post_receive_urls = RepositoryPostReceiveUrl.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def show
    render_404
  end


  def new
    @post_receive_url = RepositoryPostReceiveUrl.new()
  end


  def create
    @post_receive_url = RepositoryPostReceiveUrl.new(params[:repository_post_receive_urls])
    @post_receive_url.repository_id = @repository.id

    respond_to do |format|
      if @post_receive_url.save
        flash[:notice] = l(:notice_post_receive_url_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_post_receive_url_create_failed)
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
      if @post_receive_url.update_attributes(params[:repository_post_receive_urls])
        flash[:notice] = l(:notice_post_receive_url_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_post_receive_url_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @post_receive_url.destroy
        flash[:notice] = l(:notice_post_receive_url_deleted)
        format.js { render :js => "window.location = #{success_url.to_json};" }
      else
        format.js { render :layout => false }
      end
    end
  end


  protected


  def find_repository_post_receive_url
    post_receive_url = RepositoryPostReceiveUrl.find_by_id(params[:id])

    if post_receive_url && post_receive_url.repository_id == @repository.id
      @post_receive_url = post_receive_url
    elsif post_receive_url
      render_403
    else
      render_404
    end
  end


end
