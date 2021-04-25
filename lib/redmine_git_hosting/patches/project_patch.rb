# frozen_string_literal: true

module RedmineGitHosting
  module Patches
    module ProjectPatch
      def self.prepended(base)
        base.class_eval do
          # Add custom scope
          scope :active_or_closed, -> { where status: [Project::STATUS_ACTIVE, Project::STATUS_CLOSED] }

          # Make sure that identifier does not match Gitolite Admin repository
          validates_exclusion_of :identifier, in: %w[gitolite-admin]

          # Place additional constraints on repository identifiers because of multi repos
          validate :additional_constraints_on_identifier
        end
      end

      # Find all repositories owned by project which are Repository::Xitolite
      def gitolite_repos
        repositories.select { |x| x.is_a? Repository::Xitolite }.sort_by(&:id)
      end

      # Return first repo with a blank identifier (should be only one!)
      def repo_blank_ident
        scope = Repository.where project_id: id
        scope.where(identifier: nil).or(scope.where(identifier: '')).first
      end

      def users_available
        get_members_available User
      end

      def groups_available
        get_members_available Group
      end

      private

      def get_members_available(klass)
        principals = memberships.active.map(&:principal)
        principals.select! { |m| m.instance_of? klass }
        principals.uniq!
        principals.sort
      end

      def additional_constraints_on_identifier
        # Make sure that identifier does not match existing repository identifier
        return unless new_record? && identifier.present? && Repository.find_by(identifier: identifier, type: 'Repository::Xitolite')

        errors.add :identifier, :taken
      end
    end
  end
end

Project.prepend RedmineGitHosting::Patches::ProjectPatch unless Project.included_modules.include? RedmineGitHosting::Patches::ProjectPatch
