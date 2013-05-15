module RedmineGitHosting
  module Hooks
    class MyAccountHook < Redmine::Hook::ViewListener
      render_on :view_my_account_show_right, :partial => 'gitolite_public_keys/view'
    end
  end
end
