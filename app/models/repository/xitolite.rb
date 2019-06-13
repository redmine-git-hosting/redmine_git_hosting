require_dependency 'redmine/scm/adapters/xitolite_adapter'

class Repository::Xitolite < Repository::Git
  # Include Gitolitable concern
  include Gitolitable

  # Virtual attributes
  attr_accessor :create_readme
  attr_accessor :enable_git_annex

  # Redmine uses safe_attributes on Repository, so we need to declare our virtual attributes.
  safe_attributes 'create_readme', 'enable_git_annex'

  # Relations
  has_one  :extra,                  dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitExtra'
  has_many :mirrors,                dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryMirror'
  has_many :post_receive_urls,      dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryPostReceiveUrl'
  has_many :deployment_credentials, dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryDeploymentCredential'
  has_many :git_keys,               dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitConfigKey'
  has_many :git_config_keys,        dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitConfigKey::GitConfig'
  has_many :git_option_keys,        dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitConfigKey::Option'
  has_many :protected_branches,     dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryProtectedBranche'

  # Additionnal validations
  validate :valid_repository_options, on: :create

  acts_as_watchable

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

  # Override the original method to accept options hash
  # which may contain *bypass_cache* flag.
  #
  def diff(path, rev, rev_to, opts = {})
    scm.diff(path, rev, rev_to, opts)
  end

  def rev_list(revision, args = [])
    scm.rev_list(revision, args)
  end

  def rev_parse(revision)
    scm.rev_parse(revision)
  end

  def archive(revision, format = 'tar')
    scm.archive(revision, format)
  end

  def mirror_push(url, branch, args = [])
    scm.mirror_push(url, branch, args)
  end

  private

  def valid_repository_options
    return unless Additionals.true? create_readme
    return unless Additionals.true? enable_git_annex

    errors.add(:base, :invalid_options)
  end
end
