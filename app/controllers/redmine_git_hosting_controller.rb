class RedmineGitHostingController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository
  before_filter :check_required_permissions
  before_filter :set_current_tab

  layout Proc.new { |controller| controller.request.xhr? ? false : 'base' }

  helper :git_hosting


  def show
    render_404
  end


  def edit
  end


  private


    def set_repository
      begin
        @repository = Repository::Xitolite.find(params[:repository_id])
      rescue ActiveRecord::RecordNotFound => e
        render_404
      else
        @project = @repository.project
        render_404 if @project.nil?
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
      url_for(controller: 'repositories', action: 'edit', id: @repository.id, tab: @tab)
    end

end
