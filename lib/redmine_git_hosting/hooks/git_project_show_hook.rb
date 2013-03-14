module RedmineGitHosting
  module Hooks
    class GitProjectShowHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_left, :partial => 'git_urls'
    end
  end
end
