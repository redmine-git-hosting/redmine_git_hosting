class RepositoryMirrorsController < ApplicationController
	unloadable

	before_filter :require_login
	before_filter :set_user_variable
	before_filter :find_repository_mirror, :except => [:index, :new, :create]

	menu_item :settings, :only => :settings

	def index
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

	def find_repository_mirror
		#mirror = RepositoryMirror.find_by_id(params[:id])
		mirror = RepositoryMirror.find_by_id(params[:mirror_id])

		@mirrors = @project.repository.repository_mirrors

		if mirror and mirror.user == @user
			@mirror = mirror
		elsif mirror
			render_403
		else
			render_404
		end
	end
end
