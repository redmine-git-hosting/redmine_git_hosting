module RedmineGitHosting
  module Patches
    module UsersControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :update, :git_hosting
          alias_method_chain :edit,   :git_hosting

          include GitHostingHelper
          include GitolitePublicKeysHelper

          helper :git_hosting
          helper :gitolite_public_keys
        end
      end


      module InstanceMethods

        def update_with_git_hosting(&block)
          # Set public key values for view
          set_public_key_values

          # Previous routine
          update_without_git_hosting(&block)
        end


        def edit_with_git_hosting(&block)
          # Set public key values for view
          set_public_key_values

          # Previous routine
          edit_without_git_hosting(&block)
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
