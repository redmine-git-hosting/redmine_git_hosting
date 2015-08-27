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

          alias_method_chain :plugin, :git_hosting
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


        def plugin_with_git_hosting(&block)
          @plugin = Redmine::Plugin.find(params[:id])
          return plugin_without_git_hosting(&block) unless @plugin.id == :redmine_git_hosting
          if request.post?
            @settings_form = PluginSettingsForm.new(@plugin)
            options = params[:settings].delete(:rescue){ {} }
            if @settings_form.submit(params[:settings])
              @old_settings = Setting.send("plugin_#{@plugin.id}")
              Setting.send "plugin_#{@plugin.id}=", @settings_form.params
              execute_post_actions(@old_settings, options)
              flash[:notice] = l(:notice_successful_update)
            else
              flash[:error] = @settings_form.errors.full_messages.join('<br>')
            end
            redirect_to plugin_settings_path(@plugin)
          else
            @partial = @plugin.settings[:partial]
            @settings = Setting.send "plugin_#{@plugin.id}"
          end
        end


        private


          def execute_post_actions(old_settings, opts = {})
            Settings::Apply.call(old_settings, opts)
          end

      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
