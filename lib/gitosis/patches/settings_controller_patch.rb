require_dependency 'settings_controller'
module Gitosis
  module Patches
    module SettingsControllerPatch

      def plugin_with_foo
	if params[:commit] and params[:commit] == 'Apply'
          Gitosis.update_repositories(Project.active)
	end
	plugin_without_foo
      end

      def self.included(base)
        base.class_eval do
          unloadable
        end
        base.send(:alias_method_chain, :plugin, :foo)
      end
    end
  end
end

SettingsController.send(:include, Gitosis::Patches::SettingsControllerPatch) unless SettingsController.include?(Gitosis::Patches::SettingsControllerPatch)

