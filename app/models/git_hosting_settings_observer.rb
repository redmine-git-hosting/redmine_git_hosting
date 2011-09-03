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



	def before_save

	end

	def after_save
	end
end
