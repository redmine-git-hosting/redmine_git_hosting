class RepositoryMirrorsController < ApplicationController
	unloadable

	before_filter :require_login
	before_filter :set_user_variable
	before_filter :set_poject_variable
	before_filter :check_required_permissions
	before_filter :check_xhr_request
	before_filter :find_repository_mirror, :except => [:index, :create]

	menu_item :settings, :only => :settings

	layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }

	def index
		render_404
	end

	def create
		@mirror = RepositoryMirror.new(params[:repository_mirrors])
		if request.get?
			# display create view
		else
			@mirror.update_attributes(params[:repository_mirrors])
			@mirror.project = @project

			if @mirror.save
				GitHosting.git_mirror_identity_file(@mirror)
				respond_to do |format|
					format.html {
						redirect_to(
							url_for(
								:controller => 'projects',
								:action => 'settings',
								:id => @mirror.project.identifier,
								:tab => 'repository'
							),
							:notice => l(:mirror_notice_created)
						)
					}
				end
			else
				respond_to do |format|
					flash[:notice] = l(:mirror_notice_create_failed)
				end
			end
		end
	end

	def edit
	end

	def update
		respond_to do |format|
			if @mirror.update_attributes(params[:repository_mirrors])
				GitHosting.git_mirror_identity_file(@mirror)
				format.html {
					redirect_to(
						url_for(
							:controller => 'projects',
							:action => 'settings',
							:id => @mirror.project.identifier,
							:tab => 'repository'
						),
						:notice => l(:mirror_notice_updated)
					)
				}
			else
				format.html { render :action => "edit" }
			end
		end


	end

	def destroy
		if request.get?
			# display confirmation view
		else
			if params[:confirm]
				identify_file = GitHosting.git_mirror_identity_file(@mirror)
				%x[#{git_user_runner} rm #{identify_file}]
				redirect_url = url_for(
					:controller => 'projects',
					:action => 'settings',
					:id => @mirror.project.identifier,
					:tab => 'repository'
				)
				@mirror.destroy
				respond_to do |format|
					format.html {redirect_to(redirect_url, :notice => l(:mirror_notice_deleted))}
				end
			end
		end
	end

	def settings
	end

	def push
		respond_to do |format|
			format.html {
				@shellout = %x{ export GIT_MIRROR_IDENTITY_FILE=#{GitHosting.git_mirror_identity_file(@mirror)}; export GIT_SSH='#{GitHosting.git_exec_mirror}'; #{GitHosting.git_exec} --git-dir='#{GitHosting.repository_path(@project)}.git' push --mirror '#{@mirror.url}' 2>&1 }
				@push_failed = ($?.to_i!=0) ? true : false
				if @push_failed
					ms = " #{@mirror.url} push error "
					nr = (70-ms.length)/2
					GitHosting.logger.debug "Failed:\n%{nrs} #{ms} %{nrs}\n#{@shellout}%{nre} #{ms} %{nre}\n" % {:nrs => ">"*nr, :nre => "<"*nr}
				end
			}
		end
	end

	protected

	def set_user_variable
		@user = User.current
	end

	def set_poject_variable
		@project = Project.find(:first, :conditions => ["identifier = ?", params[:project_id]])
	end

	def find_repository_mirror
		mirror = RepositoryMirror.find_by_id(params[:id])

		@mirrors = @project.repository_mirrors

		if mirror and mirror.project == @project
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

	def check_xhr_request
		@is_xhr ||= request.xhr?
	end

end
