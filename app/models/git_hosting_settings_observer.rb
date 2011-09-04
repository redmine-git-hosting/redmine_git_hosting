class GitHostingSettingsObserver < ActiveRecord::Observer
	observe :setting

	@@old_hook_debug = Setting.plugin_redmine_git_hosting['gitHooksDebug']
	@@old_http_server = Setting.plugin_redmine_git_hosting['httpServer']
	@@old_git_user = Setting.plugin_redmine_git_hosting['gitUser']

	def reload_this_observer
		observed_classes.each do |klass|
			klass.name.constantize.add_observer(self)
		end
	end



	def after_save(object)
		`echo after saving old is #{@@old_http_server} >>/tmp/sname.txt`
		`echo after saving new is #{object.value['httpServer']} >>/tmp/sname.txt`
		if object.name == "plugin_redmine_git_hosting"
			if @@old_git_user != Setting.plugin_redmine_git_hosting['gitUser'] 
				
				%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]
				GitHosting::Hooks::GitAdapterHooks.setup_hooks
				GitHosting.update_repositories( Project.find(:all), false)

			elsif @@old_http_server !=  Setting.plugin_redmine_git_hosting['httpServer'] || @@old_hook_debug !=  Setting.plugin_redmine_git_hosting['gitHooksDebug']

				GitHosting::Hooks::GitAdapterHooks.update_hook_url_and_debug
			
			end
			@@old_hook_debug  = object.value['gitHooksDebug']
			@@old_http_server = object.value['httpServer']
			@@old_git_user    = object.value['gitUser']
		end
	end

end
