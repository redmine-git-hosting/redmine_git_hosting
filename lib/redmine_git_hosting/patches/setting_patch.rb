require_dependency 'setting'

module RedmineGitHosting
  module Patches
    module SettingPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.class_eval do
          class << self
            alias_method_chain :check_cache, :git_hosting
          end
        end
      end


      module ClassMethods

        def check_cache_with_git_hosting
          settings_updated_on = Setting.maximum(:updated_on)
          if settings_updated_on && @cached_cleared_on <= settings_updated_on
            clear_cache
            RedmineGitHosting::Config.check_cache
          end
        end

      end

    end
  end
end

unless Setting.included_modules.include?(RedmineGitHosting::Patches::SettingPatch)
  Setting.send(:include, RedmineGitHosting::Patches::SettingPatch)
end
