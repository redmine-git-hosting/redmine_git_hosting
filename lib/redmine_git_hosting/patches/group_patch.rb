require_dependency 'group'

module RedmineGitHosting
  module Patches
    module GroupPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          # Relations
          has_many :protected_branches_members, dependent: :destroy, foreign_key: :principal_id
          has_many :protected_branches, through: :protected_branches_members

          alias_method_chain :user_added,   :git_hosting
          alias_method_chain :user_removed, :git_hosting
        end
      end


      module InstanceMethods

        def user_added_with_git_hosting(user, &block)
          user_added_without_git_hosting(user, &block)
          protected_branches.each do |pb|
            RepositoryProtectedBranches::MemberManager.new(pb).add_user_from_group(user, self.id)
          end
        end


        def user_removed_with_git_hosting(user, &block)
          user_removed_without_git_hosting(user, &block)
          protected_branches.each do |pb|
            RepositoryProtectedBranches::MemberManager.new(pb).remove_user_from_group(user, self.id)
          end
        end

      end

    end
  end
end

unless Group.included_modules.include?(RedmineGitHosting::Patches::GroupPatch)
  Group.send(:include, RedmineGitHosting::Patches::GroupPatch)
end
