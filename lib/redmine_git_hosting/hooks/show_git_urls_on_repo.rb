module RedmineGitHosting
  module Hooks
    class ShowGitUrlsOnRepo < Redmine::Hook::ViewListener
      render_on :view_repositories_show_contextual, :partial => 'repositories/git_urls'
    end
  end
end
