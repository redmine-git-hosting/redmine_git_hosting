module RedmineGitHosting
  module Hooks
    class AddPluginIcon < Redmine::Hook::ViewListener

      def view_layouts_base_html_head(context={})
        return stylesheet_link_tag(:application, :plugin => 'redmine_git_hosting')
      end

    end
  end
end
