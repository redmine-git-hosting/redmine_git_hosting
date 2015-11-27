module RedmineGitHosting
  module Hooks
    class DisplayGitUrlsOnRepositoryShow < Redmine::Hook::ViewListener
      render_on :view_repositories_show_contextual, partial: 'repositories/show_top'
    end
  end
end
