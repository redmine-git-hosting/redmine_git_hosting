module RedmineGitHosting
  module Patches
    module SettingsControllerPatch
      unloadable

      def self.included(base)
        base.class_eval do
          unloadable

          helper :git_hosting
          include GitHostingHelper
        end
      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
