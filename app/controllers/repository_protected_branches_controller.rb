class RepositoryProtectedBranchesController < RedmineGitHostingController
  unloadable

  before_filter :can_view_protected_branches,   :only => [:index]
  before_filter :can_create_protected_branches, :only => [:new, :create]
  before_filter :can_edit_protected_branches,   :only => [:edit, :update, :destroy]

  before_filter :find_repository_protected_branch, :except => [:index, :new, :create, :sort]


  def index
    @repository_protected_branches = @repository.protected_branches.all
    respond_to do |format|
      format.html { render :layout => 'popup' }
      format.js
    end
  end


  def new
    @protected_branch = @repository.protected_branches.new()
    @protected_branch.user_list  = []
  end


  def create
    @protected_branch = @repository.protected_branches.new(params[:repository_protected_branche])
    respond_to do |format|
      if @protected_branch.save
        flash[:notice] = l(:notice_protected_branch_created)

        # Update Gitolite repository
        call_use_case

        format.html { redirect_to success_url }
        format.js   { render :js => "window.location = #{success_url.to_json};" }
      else
        format.html {
          flash[:error] = l(:notice_protected_branch_create_failed)
          render :action => "new"
        }
        format.js { render "form_error", :layout => false }
      end
    end
  end


  def update
    respond_to do |format|
      if @protected_branch.update_attributes(params[:repository_protected_branche])
        flash[:notice] = l(:notice_protected_branch_updated)

        # Update Gitolite repository
        call_use_case

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

        # Update Gitolite repository
        call_use_case

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


  def sort
    params[:repository_protected_branche].each_with_index do |id, index|
      @repository.protected_branches.update_all({position: index + 1}, {id: id})
    end

    # Update Gitolite repository
    call_use_case

    render :nothing => true
  end


  private


    def set_current_tab
      @tab = 'repository_protected_branches'
    end


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
      @protected_branch = @repository.protected_branches.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_404
    end


    def call_use_case
      options = { message: "Update branch permissions for repository : '#{@repository.gitolite_repository_name}'" }
      UpdateRepository.new(@repository, options).call
    end

end
