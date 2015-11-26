require_dependency 'repositories_helper'

module RedmineGitHosting
  module Patches
    module RepositoriesHelperPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          # First alias xitolite_field_tags to git_field_tags
          # to define the method otherwise the method is not created...
          # (don't know why...)
          alias :xitolite_field_tags :git_field_tags

          # Then chain it with our own method to add/remove fields
          alias_method_chain :xitolite_field_tags, :git_hosting
        end
      end


      module InstanceMethods

        def xitolite_field_tags_with_git_hosting(form, repository)
          # Extending Helpers is a bit tricky.
          # These methods are defined in ExtendRepositoriesHelper module
          # which is loaded in RepositoriesControllerPatch.
          encoding_field(form, repository) +
          create_readme_field(form, repository) +
          enable_git_annex_field(form, repository)
        end

      end

    end
  end
end

unless RepositoriesHelper.included_modules.include?(RedmineGitHosting::Patches::RepositoriesHelperPatch)
  RepositoriesHelper.send(:include, RedmineGitHosting::Patches::RepositoriesHelperPatch)
end
