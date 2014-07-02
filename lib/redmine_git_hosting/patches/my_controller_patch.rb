require_dependency 'my_controller'

module RedmineGitHosting
  module Patches
    module MyControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :account, :git_hosting

          helper :gitolite_public_keys
        end
      end


      module InstanceMethods

        def account_with_git_hosting(&block)
          # Previous routine
          account_without_git_hosting(&block)

          # Set public key values for view
          set_public_key_values
        end


        private


        # Add in values for viewing public keys:
        def set_public_key_values
          @gitolite_user_keys   = @user.gitolite_public_keys.user_key.order('title ASC, created_at ASC')
          @gitolite_deploy_keys = @user.gitolite_public_keys.deploy_key.order('title ASC, created_at ASC')
          @gitolite_public_key  = GitolitePublicKey.new
        end

      end


    end
  end
end

unless MyController.included_modules.include?(RedmineGitHosting::Patches::MyControllerPatch)
  MyController.send(:include, RedmineGitHosting::Patches::MyControllerPatch)
end
