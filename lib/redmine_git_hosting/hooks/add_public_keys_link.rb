module RedmineGitHosting
  module Hooks
    class AddPublicKeysLink < Redmine::Hook::ViewListener
      render_on :view_my_account_contextual, :inline => "| <%= link_to l(:label_my_public_keys), public_keys_path, :class => 'icon icon-passwd' %>"
    end
  end
end
