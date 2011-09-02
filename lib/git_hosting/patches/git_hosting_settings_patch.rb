require_dependency 'settings_controller'

module GitHosting
	module Patches
		module GitHostingSettingsPatch

			def plugin_with_hook_settings_update

				plugin_without_hook_settings_update

				t = Thread.new do
					# Let's sleep a while to allow the db settings to be saved
					sleep 1.5
					GitHosting::Hooks::GitAdapterHooks.update_hook_url_and_debug()
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
