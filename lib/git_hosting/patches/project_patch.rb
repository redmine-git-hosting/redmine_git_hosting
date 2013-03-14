require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'project'

module GitHosting
  module Patches
    module ProjectPatch

      # Find all repositories owned by project which are Repository::Git
      # Works for both multi- and single- repo/project
      def gl_repos
        all_repos.select{|x| x.is_a?(Repository::Git)}
      end

      # Find all repositories owned by project.  Works for both multi- and
      # single- repo/project
      def all_repos
        if GitHosting.multi_repos?
          repositories
        else
          [ repository ].compact
        end
      end

      # Return first repo with a blank identifier (should be only one!)
      def repo_blank_ident
        Repository.find_by_project_id(id,:conditions => ["identifier = '' or identifier is null"])
      end

      # Make sure that identifier does not match existing repository identifier
      # Only for Redmine 1.4
      def additional_ident_constraints
        if new_record? && !identifier.blank? && Repository.find_by_identifier_and_type(identifier,"Git")
          errors.add(:identifier,:ident_not_unique)
        end
      end

      def self.included(base)
        base.class_eval do
          unloadable

          named_scope :archived, { :conditions => {:status => "#{Project::STATUS_ARCHIVED}"}}
          named_scope :active_or_archived, { :conditions => "status=#{Project::STATUS_ACTIVE} OR status=#{Project::STATUS_ARCHIVED}" }

          # Place additional constraints on repository identifiers
          # Only for Redmine 1.4+
          if GitHosting.multi_repos?
            validate :additional_ident_constraints
          end
        end
      end

    end
  end
end

# Patch in changes
Project.send(:include, GitHosting::Patches::ProjectPatch)
