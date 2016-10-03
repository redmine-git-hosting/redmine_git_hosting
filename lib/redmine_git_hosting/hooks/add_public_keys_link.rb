module RedmineGitHosting
  module Hooks
    class AddPublicKeysLink < Redmine::Hook::ViewListener

      def view_my_account_contextual(context)
        user = context[:user]
        link_to(l(:label_my_public_keys), public_keys_path, class: 'icon icon-passwd') if user.allowed_to_create_ssh_keys?
      end

      def self.default_url_options
        {:script_name => Redmine::Utils.relative_url_root}
      end

    end
  end
end
