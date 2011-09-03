class GitHostingSettingsObserver < ActiveRecord::Observer
	observe :setting

	@@old_hook_debug = nil
	@@old_http_server = nil
	@@old_git_user = nil

	def reload_this_observer
		observed_classes.each do |klass|
			klass.name.constantize.add_observer(self)
		end
	end



	def before_save(object)
		if object.name == "plugin_redmine_git_hosting"
			update_cached_vars
		end
	end

	def after_save(object)
		if object.name == "plugin_redmine_git_hosting"
			if @@old_git_user != Setting.plugin_redmine_git_hosting['gitUser'] 
				
				%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]
				GitHosting::Hooks::GitAdapterHooks.setup_hooks
				GitHosting.update_repositories( Project.find(:all), false)

			elsif @@old_http_server !=  Setting.plugin_redmine_git_hosting['httpServer'] || @@old_http_server =  Setting.plugin_redmine_git_hosting['httpServer']

				GitHosting::Hooks::GitAdapterHooks.update_hook_url_and_debug
			
			end
			update_cached_vars
		end
	end

	private

	def update_cached_vars
		@@old_hook_debug = Setting.plugin_redmine_git_hosting['gitHooksDebug']
		@@old_http_server =  Setting.plugin_redmine_git_hosting['httpServer']
		@@old_git_user =  Setting.plugin_redmine_git_hosting['gitUser']
	end
end
