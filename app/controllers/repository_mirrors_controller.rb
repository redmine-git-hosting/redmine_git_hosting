class RepositoryMirrorsController < ApplicationController
	unloadable

	before_filter :require_login
	before_filter :set_user_variable
	before_filter :set_poject_variable
	before_filter :check_required_permissions
	before_filter :find_repository_mirror, :except => [:index, :create]

	menu_item :settings, :only => :settings

	def index
		render_404
	end

	def create

	end

	def edit
	end

	def update

	end

	def delete

	end

	def settings
	end

	protected

	def set_user_variable
		@user = User.current
	end

	def set_poject_variable
		@project = params[:project_id]
	end

	def find_repository_mirror
		mirror = RepositoryMirror.find_by_id(params[:id])

		@mirrors = @project.repository.repository_mirrors

		if mirror and mirror.user == @user
			@mirror = mirror
		elsif mirror
			render_403
		else
			render_404
		end
	end

	def check_required_permissions
		# Deny access if the curreent user is not allowed to manage the project's repositoy
		if not @project.module_enabled?(:repository)
			render_403
		end
		not_enough_perms = true
		@user.roles_for_project(@project).each{|role|
			if role.allowed_to? :manage_repository
				not_enough_perms = false
				break
			end
		}
		if not_enough_perms
			render_403
		end
	end
end
