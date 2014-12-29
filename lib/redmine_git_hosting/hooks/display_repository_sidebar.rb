module RedmineGitHosting
  module Hooks
    class DisplayRepositorySidebar < Redmine::Hook::ViewListener
      render_on :view_repositories_show_sidebar, partial: 'repositories/sidebar'
    end
  end
end
