require_dependency 'group'

module RedmineGitHosting
  module Patches
    module GroupPatch

      def self.prepended(base)
        base.class_eval do
          # Relations
          has_many :protected_branches_members, dependent: :destroy, foreign_key: :principal_id
          has_many :protected_branches, through: :protected_branches_members
        end
      end


      def user_added(user)
        super
        protected_branches.each do |pb|
          RepositoryProtectedBranches::MemberManager.new(pb).add_user_from_group(user, self.id)
        end
      end


      def user_removed(user)
        super
        protected_branches.each do |pb|
          RepositoryProtectedBranches::MemberManager.new(pb).remove_user_from_group(user, self.id)
        end
      end

    end
  end
end

unless Group.included_modules.include?(RedmineGitHosting::Patches::GroupPatch)
  Group.send(:prepend, RedmineGitHosting::Patches::GroupPatch)
end
