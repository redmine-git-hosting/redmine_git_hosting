module PluginSettingsValidation
  module RedmineConfig
    extend ActiveSupport::Concern

    included do
      # Redmine Config
      add_accessor :redmine_has_rw_access_on_all_repos,
                   :all_projects_use_git,
                   :init_repositories_on_create,
                   :delete_git_repositories,
                   :download_revision_enabled,
                   :gitolite_use_sidekiq

      # This params work together!
      # When hierarchical_organisation = true, unique_repo_identifier MUST be false
      # When hierarchical_organisation = false, unique_repo_identifier MUST be true
      add_accessor :hierarchical_organisation, :unique_repo_identifier

      # hierarchical_organisation and unique_repo_identifier are now combined
      #
      before_validation do
        self.unique_repo_identifier = if Additionals.true? hierarchical_organisation
                                        'false'
                                      else
                                        'true'
                                      end

        ## If we don't auto-create repository, we cannot create README file
        self.init_repositories_on_create = 'false' unless Additionals.true? all_projects_use_git
      end

      validates :redmine_has_rw_access_on_all_repos, presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :all_projects_use_git,               presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :init_repositories_on_create,        presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :delete_git_repositories,            presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :download_revision_enabled,          presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :gitolite_use_sidekiq,               presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :hierarchical_organisation,          presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }
      validates :unique_repo_identifier,             presence: true, inclusion: { in: RedmineGitHosting::Validators::BOOLEAN_FIELDS }

      validate :check_for_duplicated_repo
    end

    private

    # Check duplication if we are switching from a mode to another
    #
    def check_for_duplicated_repo
      return if Additionals.true?(hierarchical_organisation)
      return unless Repository::Xitolite.have_duplicated_identifier?

      errors.add(:base, 'Detected non-unique repository identifiers. Cannot switch to flat mode')
    end
  end
end
