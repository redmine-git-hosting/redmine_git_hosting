module RedmineGitHosting
  module Hooks
    class ShowGitUrlsOnRepositoryEdit < Redmine::Hook::ViewListener
      render_on :view_repository_edit_top, :partial => 'repositories/edit_top'
    end
  end
end
