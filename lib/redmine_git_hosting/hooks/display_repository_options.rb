module RedmineGitHosting
  module Hooks
    class DisplayRepositoryOptions < Redmine::Hook::ViewListener
      render_on :view_repository_form, :partial => 'repositories/git_form'
    end
  end
end
