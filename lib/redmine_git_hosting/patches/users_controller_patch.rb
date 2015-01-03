require_dependency 'users_controller'

module RedmineGitHosting
  module Patches
    module UsersControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :edit,    :git_hosting
          alias_method_chain :update,  :git_hosting
          alias_method_chain :destroy, :git_hosting

          helper :gitolite_public_keys
        end
      end


      module InstanceMethods


        def edit_with_git_hosting(&block)
          # Set public key values for view
          set_public_key_values
          # Previous routine
          edit_without_git_hosting(&block)
        end


        def update_with_git_hosting(&block)
          # Previous routine
          update_without_git_hosting(&block)
          # Update projects if needed
          update_projects
        end


        def destroy_with_git_hosting(&block)
          # Build SSH keys list before user destruction.
          ssh_keys_list = ssh_keys_to_destroy
          # Destroy user
          destroy_without_git_hosting(&block)
          # Destroy SSH keys
          destroy_ssh_keys(ssh_keys_list)
        end


        private


          # Add in values for viewing public keys:
          def set_public_key_values
            @gitolite_user_keys   = @user.gitolite_public_keys.user_key.order('title ASC, created_at ASC')
            @gitolite_deploy_keys = @user.gitolite_public_keys.deploy_key.order('title ASC, created_at ASC')
            @gitolite_public_key  = GitolitePublicKey.new
          end


          def update_projects
            options = { message: "User status has changed, update projects" }
            GitoliteAccessor.update_projects(projects_to_update, options) if @user.status_has_changed?
          end


          def projects_to_update
            @user.gitolite_projects.map{ |p| p.id }
          end


          def ssh_keys_to_destroy
            @user.gitolite_public_keys.map(&:data_for_destruction)
          end


          def destroy_ssh_keys(ssh_keys_list)
            RedmineGitHosting.logger.info("User '#{@user.login}' has been deleted from Redmine, delete membership and SSH keys !")
            ssh_keys_list.each do |ssh_key|
              GitoliteAccessor.destroy_ssh_key(ssh_key)
            end
          end

      end

    end
  end
end

unless UsersController.included_modules.include?(RedmineGitHosting::Patches::UsersControllerPatch)
  UsersController.send(:include, RedmineGitHosting::Patches::UsersControllerPatch)
end
