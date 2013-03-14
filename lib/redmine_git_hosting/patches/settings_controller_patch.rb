module RedmineGitHosting
  module Patches
    module SettingsControllerPatch
      unloadable

      def self.included(base)
        base.class_eval do
          helper :application_ext
          include ApplicationExtHelper
        end
      end

    end
  end
end

unless SettingsController.included_modules.include?(RedmineGitHosting::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineGitHosting::Patches::SettingsControllerPatch)
end
