module RedmineGitHosting
  module Patches
    module ProjectPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          if Rails::VERSION::MAJOR >= 3 && Rails::VERSION::MINOR >= 1
            scope :archived, { :conditions => {:status => "#{Project::STATUS_ARCHIVED}"}}
            scope :active_or_archived, { :conditions => "status=#{Project::STATUS_ACTIVE} OR status=#{Project::STATUS_ARCHIVED}" }
          else
            named_scope :archived, { :conditions => {:status => "#{Project::STATUS_ARCHIVED}"}}
            named_scope :active_or_archived, { :conditions => "status=#{Project::STATUS_ACTIVE} OR status=#{Project::STATUS_ARCHIVED}" }
          end

          # Place additional constraints on repository identifiers
          # Only for Redmine 1.4+
          if GitHosting.multi_repos?
            validate :additional_ident_constraints
          end
        end
      end


      module InstanceMethods

        # Find all repositories owned by project which are Repository::Git
        # Works for both multi- and single- repo/project
        def gitolite_repos
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
          Repository.find_by_project_id(id, :conditions => ["identifier = '' or identifier is null"])
        end

        private

        # Make sure that identifier does not match existing repository identifier
        # Only for Redmine 1.4
        def additional_ident_constraints
          if new_record? && !identifier.blank? && Repository.find_by_identifier_and_type(identifier, "Git")
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
