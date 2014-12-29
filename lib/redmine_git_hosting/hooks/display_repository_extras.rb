module RedmineGitHosting
  module Hooks
    class DisplayRepositoryExtras < Redmine::Hook::ViewListener
      render_on :view_repository_edit_bottom, partial: 'repositories/edit_bottom'
    end
  end
end
