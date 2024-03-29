# frozen_string_literal: true

module Gitolitable
  module Validations
    extend ActiveSupport::Concern

    included do
      # Set URL ourself as relative path.
      #
      before_validation :set_git_urls

      # Make sure that identifier does not match Gitolite Admin repository
      #
      validates :identifier, exclusion: { in: %w[gitolite-admin] }

      # Place additional constraints on repository identifiers
      # because of multi repos
      #
      validate :additional_constraints_on_identifier
      validate :identifier_dont_change
      validate :default_repository_has_identifier

      class << self
        # Build a hash of repository identifier :
        # <repo_1_identifier> => 1
        # <repo_2_identifier> => 1
        # etc...
        # If the same repository identifier is found many times, increment the corresponding counter.
        # Repository identifiers are unique if all values of the hash are 1.
        #
        def identifiers_to_hash
          all.map(&:identifier).each_with_object(Hash.new(0)) do |x, h|
            h[x] += 1 if x.present?
          end
        end

        def have_duplicated_identifier?
          (identifiers_to_hash.values.max || 0) > 1
        end
      end
    end

    def exists_in_gitolite?
      RedmineGitHosting::Commands.sudo_dir_exists? gitolite_repository_path
    end

    def empty_in_gitolite?
      RedmineGitHosting::Commands.sudo_repository_empty? gitolite_repository_path
    end

    def git_objects_count
      RedmineGitHosting::Commands.sudo_git_objects_count File.join(gitolite_repository_path, 'objects')
    end

    def empty?
      extra_info.nil? || (!extra_info.key?('heads') && !extra_info.key?('branches'))
    end

    def data_for_destruction
      {
        repo_name: gitolite_repository_name,
        repo_path: gitolite_full_repository_path,
        delete_repository: deletable?,
        git_cache_id: git_cache_id
      }
    end

    private

    # Set up git urls for new repositories
    #
    def set_git_urls
      self.url = gitolite_repository_path if url.blank?
      self.root_url = url if root_url.blank?
    end

    # Check several aspects of repository identifier (only for Redmine 1.4+)
    # 1) cannot equal identifier of any project
    # 2) if repo_ident_unique? make sure that repo identifier is globally unique
    # 3) cannot make this repo the default if there will be some other repo with blank identifier
    #
    def additional_constraints_on_identifier
      if identifier.present? && (new_record? || identifier_changed?)
        errors.add :identifier, :cannot_equal_project if Project.find_by identifier: identifier

        # See if a repo for another project has the same identifier (existing validations already check for current project)
        if self.class.repo_ident_unique? && Repository.where(identifier: identifier).where.not(project_id: project.id).any?
          errors.add :identifier, :taken
        end
      end
    end

    # Make sure identifier hasn't changed.  Allow null and blank
    # Note that simply using identifier_changed doesn't seem to work
    # if the identifier was "NULL" but the new identifier is ""
    #
    def identifier_dont_change
      return if new_record?

      if (identifier_was.blank? && identifier.present?) || (identifier_was.present? && identifier_changed?)
        errors.add :identifier, :cannot_change
      end
    end

    # Need to make sure that we don't take the default slot away from a sibling repo with blank identifier
    #
    def default_repository_has_identifier
      return unless project && (is_default? || set_as_default?)

      possibles = Repository.where project_id: project.id
      possibles = possibles.where(identifier: nil).or(possibles.where(identifier: ''))
      errors.add :base, :blank_default_exists if possibles.any? && (new_record? || possibles.detect { |x| x.id != id })
    end
  end
end
