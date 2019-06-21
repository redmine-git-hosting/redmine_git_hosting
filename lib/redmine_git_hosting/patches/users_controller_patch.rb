require_dependency 'users_controller'

module RedmineGitHosting
  module Patches
    module UsersControllerPatch
      include RedmineGitHosting::GitoliteAccessor::Methods

      def self.prepended(base)
        base.send :helper, GitHostingUsersHelper
        base.class_eval do
          helper :gitolite_public_keys
          helper :bootstrap_kit
        end
      end

      def edit
        # Set public key values for view
        set_public_key_values
        super
      end

      def update
        # Set public key values for view (in case of invalid form)
        set_public_key_values
        super

        # Update projects if needed
        update_projects if @user.status_has_changed?
      end

      def destroy
        # Build SSH keys list before user destruction.
        ssh_keys_list = ssh_keys_to_destroy

        # Destroy user
        super

        # Destroy SSH keys
        destroy_ssh_keys(ssh_keys_list)
      end

      private

      # Add in values for viewing public keys:
      def set_public_key_values
        @gitolite_user_keys   = @user.gitolite_public_keys.user_key.order('title ASC, created_at ASC')
        @gitolite_deploy_keys = @user.gitolite_public_keys.deploy_key.order('title ASC, created_at ASC')
      end

      def update_projects
        gitolite_accessor.update_projects(projects_to_update, message: "Status of '#{@user.login}' has changed, update projects")
      end

      def projects_to_update
        @user.gitolite_projects.map(&:id)
      end

      def ssh_keys_to_destroy
        @user.gitolite_public_keys.map(&:data_for_destruction)
      end

      def destroy_ssh_keys(ssh_keys_list)
        RedmineGitHosting.logger.info("User '#{@user.login}' has been deleted from Redmine, delete membership and SSH keys !")
        ssh_keys_list.each do |ssh_key|
          gitolite_accessor.destroy_ssh_key(ssh_key)
        end
      end
    end
  end
end

unless UsersController.included_modules.include?(RedmineGitHosting::Patches::UsersControllerPatch)
  UsersController.send(:prepend, RedmineGitHosting::Patches::UsersControllerPatch)
end
