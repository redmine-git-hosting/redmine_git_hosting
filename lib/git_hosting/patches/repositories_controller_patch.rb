require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'repositories_controller'

module GitHosting
    module Patches
	module RepositoriesControllerPatch
	    def show_with_git_instructions
		if @repository.is_a?(Repository::Git) and @repository.entries(@path, @rev).blank?
		    # Fake list of repos
		    @repositories = @project.all_repos
		    render :action => 'git_instructions'
		else
		    show_without_git_instructions
		end
	    end

	    # This patch is only for pre-1.4 Redmine (since they made this controller RESTful
	    def edit_with_scm_settings
		# Turn off updates during repository update
		GitHostingObserver.set_update_active(false);

		edit_without_scm_settings

		if !@repository.errors.any?
		    # Update repository extras
		    if request.post? && @repository && !params[:extra].nil?
			@repository.extra.update_attributes(params[:extra])
		    end
		    GitHostingObserver.set_update_active(@project);
		else
		    GitHostingObserver.set_update_active(true)
		end
	    end

	    # Post-1.4, all creation is done by create (rather than edit)
	    def create_with_scm_settings
		GitHostingObserver.set_update_active(false)

		# Must create repository first
		create_without_scm_settings

		if !@repository.errors.any?
		    # Update repository extras
		    if request.post? && @repository && !params[:extra].nil?
			@repository.extra.update_attributes(params[:extra])
		    end
		    GitHostingObserver.set_update_active(@project)
		else
		    GitHostingObserver.set_update_active(true)
		end
	    end

	    # Post-1.4, all of the updates are done by update (rather than edit with post)
	    def update_with_scm_settings
		GitHostingObserver.set_update_active(false)

		update_without_scm_settings

		if !@repository.errors.any?
		    # Update repository extras
		    if request.put? && @repository && !params[:extra].nil?
			@repository.extra.update_attributes(params[:extra])
		    end
		    GitHostingObserver.set_update_active(@project)
		else
		    GitHostingObserver.set_update_active(true)
		end
	    end

	    def self.included(base)
		base.class_eval do
		    unloadable
		end
		base.send(:alias_method_chain, :show, :git_instructions)

		# RESTful (post-1.4).
		base.send(:alias_method_chain, :create, :scm_settings) rescue nil

		begin
		    # RESTfull (post-1.4)
		    base.send(:alias_method_chain, :update, :scm_settings)
		rescue
		    # Not RESTfull (pre-1.4)
		    base.send(:alias_method_chain, :edit, :scm_settings) rescue nil
		end
	    end
	end
    end
end

# Patch in changes
RepositoriesController.send(:include, GitHosting::Patches::RepositoriesControllerPatch)
