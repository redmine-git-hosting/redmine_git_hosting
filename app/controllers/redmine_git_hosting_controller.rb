class RedmineGitHostingController < ApplicationController

  include XitoliteRepositoryFinder

  before_filter :require_login
  before_filter :find_xitolite_repository
  before_filter :check_required_permissions
  before_filter :set_current_tab

  layout Proc.new { |controller| controller.request.xhr? ? false : 'base' }

  helper :redmine_bootstrap_kit


  def show
    respond_to do |format|
      format.api
    end
  end


  def edit
  end


  private


    def find_repository_param
      params[:repository_id]
    end


    def check_required_permissions
      return render_403 if !@project.module_enabled?(:repository)
      return true if User.current.admin?
      return render_403 unless User.current.allowed_to_manage_repository?(@repository)
    end


    def check_xitolite_permissions
      case self.action_name
      when 'index', 'show'
        perm = "view_#{self.controller_name}".to_sym
        render_403 unless User.current.git_allowed_to?(perm, @repository)
      when 'new', 'create'
        perm = "create_#{self.controller_name}".to_sym
        render_403 unless User.current.git_allowed_to?(perm, @repository)
      when 'edit', 'update', 'destroy'
        perm = "edit_#{self.controller_name}".to_sym
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
