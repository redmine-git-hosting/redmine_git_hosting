module RedmineGitHosting
  module Hooks
    class AddPublicKeysLink < Redmine::Hook::ViewListener

      def view_my_account_contextual(context)
        user = context[:user]
        link_to(l(:label_my_public_keys), public_keys_path, class: 'icon icon-passwd') if user.allowed_to?(:create_gitolite_ssh_key, nil, global: true)
      end

    end
  end
end
