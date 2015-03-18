require_dependency 'settings_controller'

module RedmineGitHosting
  module Patches
    module SettingsControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          helper :redmine_bootstrap_kit
          helper :gitolite_plugin_settings
        end
      end

      module InstanceMethods

        def install_gitolite_hooks
          @plugin = Redmine::Plugin.find(params[:id])
          unless @plugin.id == :redmine_git_hosting
            render_404
            return
          end
          @gitolite_checks = RedmineGitHosting::Config.install_hooks!
        end

      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
