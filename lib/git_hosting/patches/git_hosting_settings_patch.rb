require_dependency 'settings_controller'

module GitHosting
	module Patches
		module GitHostingSettingsPatch

			def plugin_with_hook_settings_update
				log_level = Setting.plugin_redmine_git_hosting['loggingLevel']
				update_hooks = false
				debug_hook = Setting.plugin_redmine_git_hosting['gitHooksDebug']
				http_server = Setting.plugin_redmine_git_hosting['httpServer']


				plugin_without_hook_settings_update

				if params[:id] == 'redmine_git_hosting' and not params[:settings].nil?
					if params[:settings][:updateAllHooks]=="yes" || debug_hook != Setting.plugin_redmine_git_hosting['gitHooksDebug'] || http_server != Setting.plugin_redmine_git_hosting['httpServer'] 
						update_hooks = true
						GitHosting.logger.info("Settings changed. Updating hook settings on ALL repositories")
					end
					new_logging_level = params[:settings][:loggingLevel]
					if log_level != new_logging_level
						GitHosting.logger.info "Changing logging level from #{log_level} to #{new_logging_level}"
						Setting.plugin_redmine_git_hosting['loggingLevel'] = new_logging_level
						GitHosting.logger.level = new_logging_level.to_i
					end
				end
				if update_hooks
					t = Thread.new do
						# Let's sleep a while to allow the db settings to be saved
						sleep 1.5
						GitHosting::Hooks::GitAdapterHooks.setup_hooks()
					end
				end
			end

			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:alias_method_chain, :plugin, :hook_settings_update)
			end
		end
	end
end
SettingsController.send(:include, GitHosting::Patches::GitHostingSettingsPatch) unless SettingsController.include?(GitHosting::Patches::GitHostingSettingsPatch)
