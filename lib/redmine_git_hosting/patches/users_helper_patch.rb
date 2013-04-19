module RedmineGitHosting
  module Patches
    module UsersHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :user_settings_tabs, :public_keys
        end
      end

      module InstanceMethods

        # Add a public_keys tab to the user administration page
        def user_settings_tabs_with_public_keys
          tabs = user_settings_tabs_without_public_keys
          tabs << { :name => 'keys', :partial => 'gitolite_public_keys/view', :label => :label_public_keys }
          return tabs
        end

      end

    end
  end
end

unless UsersHelper.included_modules.include?(RedmineGitHosting::Patches::UsersHelperPatch)
  UsersHelper.send(:include, RedmineGitHosting::Patches::UsersHelperPatch)
end
