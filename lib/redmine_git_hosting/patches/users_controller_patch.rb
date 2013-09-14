module RedmineGitHosting
  module Patches
    module UsersControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # Edit adds new functionality, so don't silently fail!
          alias_method_chain :edit,               :public_keys
          alias_method_chain :create,             :git_hosting
          alias_method_chain :update,             :git_hosting
          alias_method_chain :edit_membership,    :git_hosting
          alias_method_chain :destroy_membership, :git_hosting

          begin
            # Put this last, since Redmine 1.1 doesn't have it....
            alias_method_chain :destroy,            :git_hosting
          rescue
          end

          helper :gitolite_public_keys
          include GitolitePublicKeysHelper
        end
      end

      module InstanceMethods

        def create_with_git_hosting(&block)
          # Turn of updates during repository update
          GitHostingObserver.set_update_active(false)
          # Do actual update
          create_without_git_hosting(&block)
          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(true)
        end

        # Add in values for viewing public keys:
        def edit_with_public_keys(&block)
          # Set public key values for view
          set_public_key_values

          # Previous routine
          edit_without_public_keys(&block)
        end

        def update_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          # Set public key values for view
          set_public_key_values
          # Do actual update
          update_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        def destroy_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          destroy_without_git_hosting(&block)
          GitHostingObserver.set_update_active(:delete)
        end

        def edit_membership_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          edit_membership_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        def destroy_membership_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          destroy_membership_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        private

        # Add in values for viewing public keys:
        def set_public_key_values
          @gitolite_user_keys   = @user.gitolite_public_keys.active.user_key.find(:all,:order => 'title ASC, created_at ASC')
          @gitolite_deploy_keys = @user.gitolite_public_keys.active.deploy_key.find(:all,:order => 'title ASC, created_at ASC')
          @gitolite_public_keys = @gitolite_user_keys + @gitolite_deploy_keys
          @gitolite_public_key  = @gitolite_public_keys.detect{|x| x.id == params[:public_key_id].to_i}

          if @gitolite_public_key.nil?
            if params[:public_key_id]
              # public_key specified that doesn't belong to @user. Kill off public_key_id and try again
              redirect_to :public_key_id => nil, :tab => nil
              return
            else
              @gitolite_public_key = GitolitePublicKey.new
            end
          end
        end

      end

    end
  end
end

unless UsersController.included_modules.include?(RedmineGitHosting::Patches::UsersControllerPatch)
  UsersController.send(:include, RedmineGitHosting::Patches::UsersControllerPatch)
end
