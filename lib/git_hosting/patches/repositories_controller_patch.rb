require_dependency 'repositories_controller'
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

				# Update the git_repositories_extras table
				# This needs to be done here because after some tries of adding,
				# at runtime, accepts_nested_attributes_for, they all failed, and
				# seemed too hacky.
				if !@project.repository.nil?
					@project.repository.extra.update_attributes(params[:extra])
					@project.repository.extra.save
				end
				

				edit_without_scm_settings
				GitHosting.logger.debug "On edit_with_scm_settings after edit_without_scm_settings"

				GitHosting::update_repositories(@project, false) if !@project.repository.nil?
				# Make sure the repository has updated hook settings
				GitHosting::Hooks::GitAdapterHooks.setup_hooks(@project) if !@project.repository.nil?
				
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
RepositoriesController.send(:include, GitHosting::Patches::RepositoriesControllerPatch) unless RepositoriesController.include?(GitHosting::Patches::RepositoriesControllerPatch)
