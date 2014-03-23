class RepositoryProtectedBranchesController < RedmineGitHostingController
  unloadable

  before_filter :set_current_tab
  before_filter :can_view_protected_branches,   :only => [:index]
  before_filter :can_create_protected_branches, :only => [:new, :create]
  before_filter :can_edit_protected_branches,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_protected_branch, :except => [:index, :new, :create]


  def index
    @repository_protected_branches = RepositoryProtectedBranche.find_all_by_repository_id(@repository.id)

    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def new
    @protected_branch = RepositoryProtectedBranche.new()
  end


  def create
    @protected_branch = RepositoryProtectedBranche.new(params[:repository_protected_branches])
    @protected_branch.repository = @repository

    respond_to do |format|
      if @protected_branch.save
        flash[:notice] = l(:notice_protected_branch_created)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_protected_branch_create_failed)
          render :action => "create"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def update
    respond_to do |format|
      if @protected_branch.update_attributes(params[:repository_protected_branches])
        flash[:notice] = l(:notice_protected_branch_updated)

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_protected_branch_update_failed)
          render :action => "edit"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def destroy
    respond_to do |format|
      if @protected_branch.destroy
        flash[:notice] = l(:notice_protected_branch_deleted)
        format.js { render :js => "window.location = #{success_url.to_json};" }
      else
        format.js { render :layout => false }
      end
    end
  end


  def clone
    @protected_branch = RepositoryProtectedBranche.clone_from(params[:id])
    render "new"
  end


  private


  def can_view_protected_branches
    render_403 unless view_context.user_allowed_to(:view_repository_protected_branches, @project)
  end


  def can_create_protected_branches
    render_403 unless view_context.user_allowed_to(:create_repository_protected_branches, @project)
  end


  def can_edit_protected_branches
    render_403 unless view_context.user_allowed_to(:edit_repository_protected_branches, @project)
  end


  def find_repository_protected_branch
    protected_branch = RepositoryProtectedBranche.find_by_id(params[:id])

    if protected_branch && protected_branch.repository_id == @repository.id
      @protected_branch = protected_branch
    elsif protected_branch
      render_403
    else
      render_404
    end
  end


  def set_current_tab
    @tab = 'repository_protected_branches'
  end

end
