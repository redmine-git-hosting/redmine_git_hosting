require_dependency 'users_helper'

module RedmineGitHosting
  module Patches
    module UsersHelperPatch

      def self.prepended(base)
        base.class_eval do
          alias_method :user_settings_tabs_without_git_hosting, :user_settings_tabs
          alias_method :user_settings_tabs, :user_settings_tabs_with_git_hosting
        end
      end


      # Add a public_keys tab to the user administration page
      def user_settings_tabs_with_git_hosting(&block)
        tabs = user_settings_tabs_without_git_hosting(&block)
        tabs << { name: 'keys', partial: 'gitolite_public_keys/view', label: :label_public_keys }
        tabs
      end

    end
  end
end

unless UsersHelper.included_modules.include?(RedmineGitHosting::Patches::UsersHelperPatch)
  UsersHelper.send(:prepend, RedmineGitHosting::Patches::UsersHelperPatch)
end
