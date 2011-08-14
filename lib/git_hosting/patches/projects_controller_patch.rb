require_dependency 'projects_controller'
module GitHosting
	module Patches
		module ProjectsControllerPatch

			def git_repo_init

				users = @project.member_principals.map(&:user).compact.uniq
				if users.length == 0
					membership = Member.new(
						:principal=>User.current,
						:project_id=>@project.id,
						:role_ids=>[3]
						)
					membership.save
				end
				if @project.module_enabled?('repository') && Setting.plugin_redmine_git_hosting['allProjectsUseGit'] == "true"
					repo = Repository::Git.new
					repo_name= @project.parent ? File.join(GitHosting::get_full_parent_path(@project, true),@project.identifier) : @project.identifier
					repo.url = repo.root_url = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{repo_name}.git")
					@project.repository = repo
				end

			end

			def disable_git_daemon_if_not_public
				if @project.repository != nil
					if @project.repository.is_a?(Repository::Git)
						if @project.repository.extra.git_daemon == 1 && (not @project.is_public )
							@project.repository.extra.git_daemon = 0;
							@project.repository.save
						end
					end
				end
			end

			def update_git_repo_for_new_parent
				if @project.repository != nil
					if @project.repository.is_a?(Repository::Git)
						old_parent_id = @project.parent ? @project.parent.id : nil
						new_parent_id = params[:project].has_key?('parent_id') ? params[:project]['parent_id'] : nil
						old_parent_id = old_parent_id.to_s.strip.chomp == "" ? nil : old_parent_id
						new_parent_id = new_parent_id.to_s.strip.chomp == "" ? nil : new_parent_id
						if old_parent_id.to_s != new_parent_id.to_s
							old_parent = old_parent_id != nil ? Project.find_by_id(old_parent_id) : nil
							new_parent = new_parent_id != nil ? Project.find_by_id(new_parent_id) : nil

							old_name = old_parent.is_a?(Project) ? File.join(GitHosting::get_full_parent_path(old_parent, true), old_parent.identifier,@project.identifier).gsub(/^\//, "") :  @project.identifier
							new_name = new_parent.is_a?(Project) ? File.join(GitHosting::get_full_parent_path(new_parent, true), new_parent.identifier,@project.identifier).gsub(/^\//, "") :  @project.identifier

							@project.repository.url = @project.repository.root_url = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], "#{new_name}.git")
							@project.repository.save
							GitHosting::move_repository( old_name, new_name )
						end
					end
				end
			end



			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:after_filter, :git_repo_init, :only=>:create)

				base.send(:before_filter, :update_git_repo_for_new_parent, :only=>:update)
				base.send(:after_filter, :disable_git_daemon_if_not_public, :only=>:update)
			end
		end
	end
end
ProjectsController.send(:include, GitHosting::Patches::ProjectsControllerPatch) unless ProjectsController.include?(GitHosting::Patches::ProjectsControllerPatch)
