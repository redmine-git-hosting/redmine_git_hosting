module RedmineGitHosting
  module Hooks
    class AddPluginIcon < Redmine::Hook::ViewListener

      def view_layouts_base_html_head(context = {})
        header = ''
        header << stylesheet_link_tag(:application, plugin: 'redmine_git_hosting') + "\n"
        header << javascript_include_tag(:plugin, plugin: 'redmine_git_hosting') + "\n"
        header
      end

    end
  end
end
