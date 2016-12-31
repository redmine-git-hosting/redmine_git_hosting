require_dependency 'repositories_helper'

module RedmineGitHosting
  module Patches
    module RepositoriesHelperPatch

      def xitolite_field_tags(form, repository)
        encoding_field(form, repository) +
        create_readme_field(form, repository) +
        enable_git_annex_field(form, repository)
      end

    end
  end
end

unless RepositoriesHelper.included_modules.include?(RedmineGitHosting::Patches::RepositoriesHelperPatch)
  RepositoriesHelper.send(:prepend, RedmineGitHosting::Patches::RepositoriesHelperPatch)
end
