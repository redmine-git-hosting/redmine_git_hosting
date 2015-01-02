module Gitolitable
  extend ActiveSupport::Concern

  included do
    before_validation :set_git_urls

    # Validate that identifier does not match Gitolite Admin repository
    validates_exclusion_of :identifier, in: %w(gitolite-admin)

    # Place additional constraints on repository identifiers
    # because of multi repos
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
        self.all.map(&:identifier).inject(Hash.new(0)) do |h, x|
          h[x] += 1 unless x.blank?
          h
        end
      end


      def have_duplicated_identifier?
        (identifiers_to_hash.values.max || 0) > 1
      end

    end

  end


  def report_last_commit
    # Always true
    true
  end


  def extra_report_last_commit
    # Always true
    true
  end


  def default_branch
    extra[:default_branch]
  end


  def gitolite_hook_key
    extra[:key]
  end


  def data_for_destruction
    {
      repo_name: gitolite_repository_name,
      repo_path: gitolite_repository_path,
      delete_repository: deletable?,
      git_cache_id: git_cache_id
    }
  end


  def downloadable?
    if extra[:git_annex]
      false
    elsif project.active?
      User.current.allowed_to?(:download_git_revision, project)
    else
      User.current.allowed_to?(:download_git_revision, nil, global: true)
    end
  end


  def urls_are_viewable?
    RedmineGitHosting::Config.show_repositories_url? && User.current.allowed_to?(:view_changesets, project)
  end


  def clonable_via_http?
    User.anonymous.allowed_to?(:view_changesets, project) || extra[:git_http] != 0
  end


  def pushable_via_http?
    extra[:git_http] == 1 || extra[:git_http] == 2
  end


  def notifiable?
    extra[:git_notify]
  end


  def git_web_enable?
    User.anonymous.allowed_to?(:browse_repository, project) && extra[:git_http] != 0
  end


  def git_daemon_enable?
    User.anonymous.allowed_to?(:view_changesets, project) && extra[:git_daemon]
  end


  def protected_branches_enabled?
    project.active? && extra[:protected_branch] && protected_branches.any?
  end


  def deletable?
    RedmineGitHosting::Config.delete_git_repositories?
  end


  private


    # Set up git urls for new repositories
    def set_git_urls
      self.url = gitolite_repository_path if self.url.blank?
      self.root_url = self.url if self.root_url.blank?
    end


    # Check several aspects of repository identifier (only for Redmine 1.4+)
    # 1) cannot equal identifier of any project
    # 2) if repo_ident_unique? make sure that repo identifier is globally unique
    # 3) cannot make this repo the default if there will be some other repo with blank identifier
    def additional_constraints_on_identifier
      if !identifier.blank? && (new_record? || identifier_changed?)
        errors.add(:identifier, :cannot_equal_project) if Project.find_by_identifier(identifier)

        # See if a repo for another project has the same identifier (existing validations already check for current project)
        errors.add(:identifier, :taken) if self.class.repo_ident_unique? && Repository.find_by_identifier(identifier, conditions: ["project_id <> ?", project.id])
      end
    end


    # Make sure identifier hasn't changed.  Allow null and blank
    # Note that simply using identifier_changed doesn't seem to work
    # if the identifier was "NULL" but the new identifier is ""
    #
    def identifier_dont_change
      return if new_record?
      errors.add(:identifier, :cannot_change) if (identifier_was.blank? && !identifier.blank? || !identifier_was.blank? && identifier_changed?)
    end


    # Need to make sure that we don't take the default slot away from a sibling repo with blank identifier
    #
    def default_repository_has_identifier
      if project && (is_default? || set_as_default?)
        possibles = Repository.find_all_by_project_id(project.id, conditions: ["identifier = '' or identifier is null"])
        errors.add(:base, :blank_default_exists) if possibles.any? && (new_record? || possibles.detect{ |x| x.id != id })
      end
    end

end
