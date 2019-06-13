class RedmineGitHostingController < ApplicationController
  include XitoliteRepositoryFinder

  before_action :require_login
  before_action :find_xitolite_repository
  before_action :check_required_permissions
  before_action :set_current_tab

  layout(proc { |controller| controller.request.xhr? ? false : 'base' })

  helper :bootstrap_kit

  def show
    respond_to do |format|
      format.api
    end
  end

  def edit; end

  private

  def find_repository_param
    params[:repository_id]
  end

  def check_required_permissions
    return render_403 unless @project.module_enabled?(:repository)
    return true if User.current.admin?
    return render_403 unless User.current.allowed_to_manage_repository?(@repository)
  end

  def check_xitolite_permissions
    case action_name
    when 'index', 'show'
      perm = "view_#{controller_name}".to_sym
      render_403 unless User.current.git_allowed_to?(perm, @repository)
    when 'new', 'create'
      perm = "create_#{controller_name}".to_sym
      render_403 unless User.current.git_allowed_to?(perm, @repository)
    when 'edit', 'update', 'destroy'
      perm = "edit_#{controller_name}".to_sym
      render_403 unless User.current.git_allowed_to?(perm, @repository)
    end
  end

  def render_with_api
    respond_to do |format|
      format.html { render layout: false }
      format.api
    end
  end

  def render_js_redirect
    respond_to do |format|
      format.js { render js: "window.location = #{success_url.to_json};" }
    end
  end

  def success_url
    url_for(controller: 'repositories', action: 'edit', id: @repository.id, tab: @tab)
  end

  def call_use_case_and_redirect(opts = {})
    # Update Gitolite repository
    call_use_case(opts)
    render_js_redirect
  end
end
