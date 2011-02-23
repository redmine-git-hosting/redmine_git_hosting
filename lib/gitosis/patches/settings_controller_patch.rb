require_dependency 'settings_controller'
module Gitosis
  module Patches
    module SettingsControllerPatch

      def plugin_with_update_repo
        @plugin = Redmine::Plugin.find(params[:id])

        plugin_without_update_repo

        if @plugin.id.to_s == 'redmine_gitosis' and
            request.post? and params[:commit] and params[:commit] == 'Apply'
          Setting.plugin_redmine_gitosis = Setting['plugin_redmine_gitosis']
          Gitosis.update_repositories(Project.active)
        end
      end

      def self.included(base)
        base.class_eval do
          unloadable
        end
        base.send(:alias_method_chain, :plugin, :update_repo)
      end
    end
  end
end

SettingsController.send(:include, Gitosis::Patches::SettingsControllerPatch) unless SettingsController.include?(Gitosis::Patches::SettingsControllerPatch)

