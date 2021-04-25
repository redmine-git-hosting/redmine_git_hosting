# frozen_string_literal: true

module RedmineGitHosting
  module Patches
    module DashboardContentProjectPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def block_definitions
          blocks = super

          blocks['giturls'] = { label: l(:label_repository_url_plural),
                                permission: :manage_repository,
                                no_settings: true,
                                partial: 'dashboards/blocks/git_urls' }

          blocks
        end
      end
    end
  end
end

if DashboardContentProject.included_modules.exclude? RedmineGitHosting::Patches::DashboardContentProjectPatch
  DashboardContentProject.include RedmineGitHosting::Patches::DashboardContentProjectPatch
end
