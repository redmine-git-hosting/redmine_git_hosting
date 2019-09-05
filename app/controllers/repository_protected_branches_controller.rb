class RepositoryProtectedBranchesController < RedmineGitHostingController
  include RedmineGitHosting::GitoliteAccessor::Methods

  before_action :check_xitolite_permissions
  before_action :find_repository_protected_branch, except: %i[index new create sort]

  accept_api_auth :index, :show

  def index
    @repository_protected_branches = @repository.protected_branches.all
    render_with_api
  end

  def new
    @protected_branch = @repository.protected_branches.new
  end

  def create
    @protected_branch = @repository.protected_branches.new
    @protected_branch.safe_attributes = params[:repository_protected_branche]
    return unless @protected_branch.save

    check_members
    flash[:notice] = l(:notice_protected_branch_created)
    call_use_case_and_redirect
  end

  def update
    @protected_branch.safe_attributes = params[:repository_protected_branche]
    return unless @protected_branch.save

    check_members
    flash[:notice] = l(:notice_protected_branch_updated)
    call_use_case_and_redirect
  end

  def destroy
    return unless @protected_branch.destroy

    flash[:notice] = l(:notice_protected_branch_deleted)
    call_use_case_and_redirect
  end

  def clone
    @protected_branch = RepositoryProtectedBranche.clone_from(params[:id])
    render 'new'
  end

  def sort
    params[:protected_branch].each_with_index do |id, index|
      @repository.protected_branches.where(id: id).update_all(position: index + 1)
    end
    # Update Gitolite repository
    call_use_case
    head :ok
  end

  private

  def set_current_tab
    @tab = 'repository_protected_branches'
  end

  def find_repository_protected_branch
    @protected_branch = @repository.protected_branches.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def call_use_case(opts = {})
    options = opts.merge(message: "Update branch permissions for repository : '#{@repository.gitolite_repository_name}'")
    gitolite_accessor.update_repository(@repository, options)
  end

  def check_members
    member_manager = RepositoryProtectedBranches::MemberManager.new(@protected_branch)
    member_manager.add_users(params[:user_ids])
    member_manager.add_groups(params[:group_ids])
  end
end
