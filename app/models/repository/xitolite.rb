require_dependency 'redmine/scm/adapters/xitolite_adapter'

class Repository::Xitolite < Repository::Git
  unloadable

  include Gitolitable
  include GitolitableCache
  include GitolitablePaths
  include GitolitableUrls
  include GitolitableNotifications

  # Virtual attributes
  attr_accessor :create_readme
  attr_accessor :enable_git_annex

  # Redmine uses safe_attributes on Repository, so we need to declare our virtual attributes.
  safe_attributes 'create_readme', 'enable_git_annex'

  # Relations
  has_one  :git_extra,              dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitExtra'
  has_one  :git_notification,       dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitNotification'
  has_many :mirrors,                dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryMirror'
  has_many :post_receive_urls,      dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryPostReceiveUrl'
  has_many :deployment_credentials, dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryDeploymentCredential'
  has_many :git_config_keys,        dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitConfigKey'
  has_many :protected_branches,     dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryProtectedBranche'

  # Additionnal validations
  validate :valid_repository_options, on: :create


  class << self

    def scm_adapter_class
      Redmine::Scm::Adapters::XitoliteAdapter
    end

    def scm_name
      'Gitolite'
    end

  end


  def sti_name
    'Repository::Xitolite'
  end


  def public_project?
    project.is_public?
  end


  private


    def valid_repository_options
      errors.add(:base, :invalid_options) if create_readme == 'true' && enable_git_annex == 'true'
    end

end
