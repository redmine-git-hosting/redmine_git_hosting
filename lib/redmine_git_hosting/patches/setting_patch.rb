require_dependency 'setting'

module RedmineGitHosting
  module Patches
    module SettingPatch

      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end


      module ClassMethods

        def check_cache
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
  Setting.send(:prepend, RedmineGitHosting::Patches::SettingPatch)
end
