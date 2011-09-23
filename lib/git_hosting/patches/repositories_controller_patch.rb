module GitHosting
	module Patches
		module RepositoriesControllerPatch
			def show_with_git_instructions
				if @repository.is_a?(Repository::Git) and @repository.entries(@path, @rev).blank?
					render :action => 'git_instructions'
				else
					show_without_git_instructions
				end
			end

			def edit_with_scm_settings
				GitHosting.logger.debug "On edit_with_scm_settings"
				params[:repository] ||= {}
				if params[:repository_scm] == "Git"
					repo_name= @project.parent ? File.join(GitHosting::get_full_parent_path(@project, true),@project.identifier) : @project.identifier
					params[:repository][:url] = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{repo_name}.git")
				end

				if params[:repository_scm] == "Git" || @project.repository.is_a?(Repository::Git)
					#Evidently the ONLY way to update the repository.extra table is to basically copy/paste the existing controller code
					#the update line needs to go in the dead center of it.
					@repository = @project.repository
					if !@repository
						@repository = Repository.factory(params[:repository_scm])
						@repository.project = @project if @repository
					end
					if request.post? && @repository
						@repository.attributes = params[:repository]
						if !params[:extra].nil?
							@repository.extra.update_attributes(params[:extra])
						end
						@repository.save
					end


					render(:update) do |page|
						page.replace_html "tab-content-repository", :partial => 'projects/settings/repository'
						if @repository && !@project.repository
							@project.reload #needed to reload association
							page.replace_html "main-menu", render_main_menu(@project)
						end
					end

					GitHosting.update_repositories(@project, false) if !@project.repository.nil?
					GitHosting.setup_hooks(@project) if !@project.repository.nil?

				else
					edit_without_scm_settings
				end


			end

			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:alias_method_chain, :show, :git_instructions)
				base.send(:alias_method_chain, :edit, :scm_settings)
			end
		end
	end
end
