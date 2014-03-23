module RedmineGitHosting
  module Patches
    module SettingsControllerPatch

      def self.included(base)
        base.class_eval do
          unloadable

          helper  :git_hosting
        end
      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
