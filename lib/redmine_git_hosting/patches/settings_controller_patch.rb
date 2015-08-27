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
            if @settings_form.submit(params[:settings])
              cleanup_tmp_dir
              Setting.send "plugin_#{@plugin.id}=", @settings_form.params
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


          def cleanup_tmp_dir
            if params[:settings][:gitolite_temp_dir] && value_is_changing?(:gitolite_temp_dir)       ||
               params[:settings][:gitolite_server_port] && value_is_changing?(:gitolite_server_port) ||
               params[:settings][:gitolite_server_host] && value_is_changing?(:gitolite_server_host)

              # Remove old tmp directory, since about to change
              RedmineGitHosting.logger.info('Cleanup temp dir')
              FileUtils.rm_rf(RedmineGitHosting::Config.gitolite_admin_dir)
            end
          end


          def value_is_changing?(setting)
            params[:settings][setting] != Setting.plugin_redmine_git_hosting[setting]
          end

      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
