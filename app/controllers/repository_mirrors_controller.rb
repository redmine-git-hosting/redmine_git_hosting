class RepositoryMirrorsController < RedmineGitHostingController
  unloadable

  before_filter :can_view_mirrors,   :only => [:index]
  before_filter :can_create_mirrors, :only => [:new, :create]
  before_filter :can_edit_mirrors,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_mirror, :except => [:index, :new, :create]


  def index
    @repository_mirrors = @repository.mirrors.all
    respond_to do |format|
      format.html { render layout: false }
    end
  end


  def new
    @mirror = @repository.mirrors.new()
  end


  def create
    @mirror = @repository.mirrors.new(params[:repository_mirror])
    respond_to do |format|
      if @mirror.save
        flash[:notice] = l(:notice_mirror_created)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js { render layout: false }
      end
    end
  end


  def update
    respond_to do |format|
      if @mirror.update_attributes(params[:repository_mirror])
        flash[:notice] = l(:notice_mirror_updated)
        format.js { render js: "window.location = #{success_url.to_json};" }
      else
        format.js { render layout: false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @mirror.destroy
        flash[:notice] = l(:notice_mirror_deleted)
        format.js { render js: "window.location = #{success_url.to_json};" }
      end
    end
  end


  def push
    respond_to do |format|
      format.html { (@push_failed, @shellout) = MirrorPush.new(@mirror).call }
    end
  end


  private


    def set_current_tab
      @tab = 'repository_mirrors'
    end


    def can_view_mirrors
      render_403 unless view_context.user_allowed_to(:view_repository_mirrors, @project)
    end


    def can_create_mirrors
      render_403 unless view_context.user_allowed_to(:create_repository_mirrors, @project)
    end


    def can_edit_mirrors
      render_403 unless view_context.user_allowed_to(:edit_repository_mirrors, @project)
    end


    def find_repository_mirror
      @mirror = @repository.mirrors.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end

end
