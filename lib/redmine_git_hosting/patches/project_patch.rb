module RedmineGitHosting
  module Patches
    module ProjectPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          scope :active_or_closed, -> { where "status = #{Project::STATUS_ACTIVE} OR status = #{Project::STATUS_CLOSED}" }

          # Place additional constraints on repository identifiers
          # because of multi repos
          validate :additional_ident_constraints
        end
      end


      module InstanceMethods

        # Find all repositories owned by project which are Repository::Git
        def gitolite_repos
          repositories.select{|x| x.is_a?(Repository::Git)}
        end

        # Return first repo with a blank identifier (should be only one!)
        def repo_blank_ident
          Repository.find_by_project_id(id, :conditions => ["identifier = '' or identifier is null"])
        end

        private

        # Make sure that identifier does not match existing repository identifier
        def additional_ident_constraints
          if new_record? && !identifier.blank? && Repository.find_by_identifier_and_type(identifier, "Repository::Git")
            errors.add(:identifier, :ident_not_unique)
          end
        end

      end

    end
  end
end

unless Project.included_modules.include?(RedmineGitHosting::Patches::ProjectPatch)
  Project.send(:include, RedmineGitHosting::Patches::ProjectPatch)
end
