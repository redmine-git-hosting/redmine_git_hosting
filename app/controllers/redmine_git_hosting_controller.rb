class RedmineGitHostingController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository_variable
  before_filter :set_project_variable
  before_filter :check_required_permissions
  before_filter :check_xhr_request

  layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }

  include GitHostingHelper
  helper  :git_hosting


  def show
    render_404
  end


  def edit
  end


  protected


  def set_repository_variable
    @repository = Repository.find_by_id(params[:repository_id])
    if @repository.nil?
      render_404
    end
  end


  def set_project_variable
    @project = @repository.project
    if @project.nil?
      render_404
    end
  end


  def check_required_permissions
    # Deny access if the current user is not allowed to manage the project's repository
    if !@project.module_enabled?(:repository)
      render_403
    end

    return true if User.current.admin?

    not_enough_perms = true

    User.current.roles_for_project(@project).each do |role|
      if role.allowed_to?(:manage_repository)
        not_enough_perms = false
        break
      end
    end

    if not_enough_perms
      render_403
    end
  end


  def success_url
    url_for(:controller => 'repositories', :action => 'edit', :id => @repository.id)
  end


  def check_xhr_request
    @is_xhr ||= request.xhr?
  end

end
