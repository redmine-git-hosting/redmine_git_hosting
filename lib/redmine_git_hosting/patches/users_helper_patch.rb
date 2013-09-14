module RedmineGitHosting
  module Patches
    module UsersHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :user_settings_tabs, :git_hosting
        end
      end

      module InstanceMethods

        # Add a public_keys tab to the user administration page
        def user_settings_tabs_with_git_hosting(&block)
          tabs = user_settings_tabs_without_git_hosting(&block)
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
