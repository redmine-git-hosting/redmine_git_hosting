require_dependency 'repositories_controller'
module Gitolite
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
				params[:repository] ||= {}
				if params[:repository_scm] == "Git"
					repo_name= @project.parent ? File.join(@project.parent.identifier,@project.identifier) : @project.identifier
					params[:repository][:url] = File.join(Setting.plugin_redmine_gitolite['gitRepositoryBasePath'], "#{repo_name}.git")
				end
				
				edit_without_scm_settings
			
				Gitolite::update_repositories(@project)
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
RepositoriesController.send(:include, Gitolite::Patches::RepositoriesControllerPatch) unless RepositoriesController.include?(Gitolite::Patches::RepositoriesControllerPatch)
