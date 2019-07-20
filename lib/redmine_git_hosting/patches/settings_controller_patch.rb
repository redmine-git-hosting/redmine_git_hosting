require_dependency 'settings_controller'

module RedmineGitHosting
  module Patches
    module SettingsControllerPatch
      def self.prepended(base)
        base.class_eval do
          helper :bootstrap_kit
          helper :gitolite_plugin_settings
        end
      end

      def authors
        @plugin = Redmine::Plugin.find(params[:id])
        return render_404 unless @plugin.id == :redmine_git_hosting

        @authors = RedmineGitHosting.authors
        render layout: false
      end

      def install_gitolite_hooks
        @plugin = Redmine::Plugin.find(params[:id])
        return render_404 unless @plugin.id == :redmine_git_hosting

        @gitolite_checks = RedmineGitHosting::Config.install_hooks!
      end

      def plugin
        @plugin = Redmine::Plugin.find(params[:id])
        return super unless @plugin.id == :redmine_git_hosting

        if request.post?
          handle_settings_update
          redirect_to plugin_settings_path(@plugin)
        else
          @partial = @plugin.settings[:partial]
          @settings = Setting.send "plugin_#{@plugin.id}"
        end
      end

      private

      def handle_settings_update
        # Create FormObject
        settings_form = PluginSettingsForm.new(@plugin)

        # Strip *rescue* hash from params as we don't want to save them
        options = params[:settings].delete(:rescue) { {} }

        # Validate form
        if settings_form.submit(params[:settings])
          # Backup old settings
          old_settings = Setting.send("plugin_#{@plugin.id}")

          # Save settings for real
          Setting.send "plugin_#{@plugin.id}=", settings_form.params

          # Execute post actions
          execute_post_actions(old_settings, options)

          flash[:notice] = l(:notice_successful_update)
        else
          flash[:error] = settings_form.errors.full_messages.join('<br>')
        end
      end

      def execute_post_actions(old_settings, opts = {})
        Settings::Apply.call(old_settings, opts)
      end
    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:prepend, RedmineGitHosting::Patches::SettingsControllerPatch)
end
