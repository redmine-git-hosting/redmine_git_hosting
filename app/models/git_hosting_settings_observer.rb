class GitHostingSettingsObserver < ActiveRecord::Observer
	observe :setting

	@@old_hook_debug   = Setting.plugin_redmine_git_hosting['gitHooksDebug']
	@@old_hook_asynch  = Setting.plugin_redmine_git_hosting['gitHooksAreAsynchronous']
	@@old_http_server  = Setting.plugin_redmine_git_hosting['httpServer']
	@@old_git_user     = Setting.plugin_redmine_git_hosting['gitUser']
	@@old_repo_base    = Setting.plugin_redmine_git_hosting['gitRepositoryBasePath']


	def reload_this_observer
		observed_classes.each do |klass|
			klass.name.constantize.add_observer(self)
		end
	end



	def after_save(object)
		if object.name == "plugin_redmine_git_hosting"

			%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]

			if @@old_repo_base != object.value['gitRepositoryBasePath']
				GitHostingObserver.set_update_active(false)
				all_projects = Project.find(:all)
				all_projects.each do |p|
					if p.repository.is_a?(Repository::Git)
						r = p.repository
						repo_name= p.parent ? File.join(GitHosting::get_full_parent_path(p, true),p.identifier) : p.identifier
						r.url = File.join(object.value['gitRepositoryBasePath'], "#{repo_name}.git")
						r.root_url = r.url
						r.save
					end
				end
				GitHostingObserver.set_update_active(true)
			end

			if @@old_git_user != object.value['gitUser']

				GitHosting.setup_hooks
				GitHosting.update_repositories( Project.find(:all), false)

			elsif @@old_http_server !=  object.value['httpServer'] || @@old_hook_debug != object.value['gitHooksDebug'] || @@old_repo_base != object.value['gitRepositoryBasePath'] || @@old_hook_asynch != object.value['gitHooksAreAsynchronous']

				GitHosting.update_global_hook_params
			end
			@@old_hook_debug   = object.value['gitHooksDebug']
			@@old_hook_asynch  = object.value['gitHooksAreAsynchronous']
			@@old_http_server  = object.value['httpServer']
			@@old_git_user     = object.value['gitUser']
			@@old_repo_base    = object.value['gitRepositoryBasePath']

		end
	end

end
