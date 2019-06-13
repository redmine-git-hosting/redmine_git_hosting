require_dependency 'project'

module RedmineGitHosting
  module Patches
    module ProjectPatch
      def self.prepended(base)
        base.class_eval do
          # Add custom scope
          scope :active_or_closed, -> { where("status = #{Project::STATUS_ACTIVE} OR status = #{Project::STATUS_CLOSED}") }

          # Make sure that identifier does not match Gitolite Admin repository
          validates_exclusion_of :identifier, in: %w(gitolite-admin)

          # Place additional constraints on repository identifiers because of multi repos
          validate :additional_constraints_on_identifier
        end
      end


      # Find all repositories owned by project which are Repository::Xitolite
      def gitolite_repos
        repositories.select { |x| x.is_a?(Repository::Xitolite) }.sort { |x, y| x.id <=> y.id }
      end


      # Return first repo with a blank identifier (should be only one!)
      def repo_blank_ident
        Repository.where("project_id = ? and (identifier = '' or identifier is null)", id).first
      end


      def users_available
        get_members_available('User')
      end


      def groups_available
        get_members_available('Group')
      end


      private


        def get_members_available(klass)
          memberships.active.map(&:principal).select { |m| m.class.name == klass }.uniq.sort
        end


        def additional_constraints_on_identifier
          if new_record? && !identifier.blank?
            # Make sure that identifier does not match existing repository identifier
            errors.add(:identifier, :taken) if Repository.find_by_identifier_and_type(identifier, 'Repository::Xitolite')
          end
        end

    end
  end
end

unless Project.included_modules.include?(RedmineGitHosting::Patches::ProjectPatch)
  Project.send(:prepend, RedmineGitHosting::Patches::ProjectPatch)
end
