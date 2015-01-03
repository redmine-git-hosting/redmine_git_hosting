require_dependency 'project'

module RedmineGitHosting
  module Patches
    module ProjectPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # Add custom scope
          scope :active_or_closed, -> { where "status = #{Project::STATUS_ACTIVE} OR status = #{Project::STATUS_CLOSED}" }

          # Make sure that identifier does not match Gitolite Admin repository
          validates_exclusion_of :identifier, in: %w(gitolite-admin)

          # Place additional constraints on repository identifiers because of multi repos
          validate :additional_constraints_on_identifier
        end
      end


      module InstanceMethods

        # Find all repositories owned by project which are Repository::Xitolite
        def gitolite_repos
          repositories.select{ |x| x.is_a?(Repository::Xitolite)}.sort { |x, y| x.id <=> y.id }
        end


        # Return first repo with a blank identifier (should be only one!)
        def repo_blank_ident
          Repository.find_by_project_id(id, conditions: ["identifier = '' or identifier is null"])
        end


        private


          def additional_constraints_on_identifier
            if new_record? && !identifier.blank?
              # Make sure that identifier does not match existing repository identifier
              errors.add(:identifier, :taken) if Repository.find_by_identifier_and_type(identifier, "Repository::Xitolite")
            end
          end

      end

    end
  end
end

unless Project.included_modules.include?(RedmineGitHosting::Patches::ProjectPatch)
  Project.send(:include, RedmineGitHosting::Patches::ProjectPatch)
end
