require_dependency 'repositories_helper'

module RedmineGitHosting
  module Patches
    module RepositoriesHelperPatch

      def self.included(base)
        base.class_eval do
          unloadable

          alias :xitolite_field_tags :git_field_tags
        end
      end

    end
  end
end

unless RepositoriesHelper.included_modules.include?(RedmineGitHosting::Patches::RepositoriesHelperPatch)
  RepositoriesHelper.send(:include, RedmineGitHosting::Patches::RepositoriesHelperPatch)
end
