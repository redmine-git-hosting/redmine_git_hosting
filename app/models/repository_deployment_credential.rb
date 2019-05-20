class RepositoryDeploymentCredential < ActiveRecord::Base
  include Redmine::SafeAttributes

  VALID_PERMS  = ['R', 'RW+'].freeze
  DEFAULT_PERM = 'RW+'.freeze

  ## Attributes
  safe_attributes 'perm', 'active', 'gitolite_public_key_id'

  ## Relations
  belongs_to :repository
  belongs_to :gitolite_public_key
  belongs_to :user

  ## Validations
  validates :repository_id,          presence: true,
                                     uniqueness: { scope: :gitolite_public_key_id }

  validates :gitolite_public_key_id, presence: true
  validates :user_id,                presence: true
  validates :perm,                   presence: true,
                                     inclusion: { in: VALID_PERMS }

  validates_associated :repository
  validates_associated :gitolite_public_key
  validates_associated :user

  validate :correct_key_type
  validate :owner_matches_key

  ## Scopes
  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def to_s
    "#{repository.identifier}-#{gitolite_public_key.identifier} : #{perm}"
  end

  # Deployment Credentials ignored unless created by someone who still has permission to create them
  def honored?
    user.admin? || user.allowed_to?(:create_repository_deployment_credentials, repository.project)
  end

  private

  def correct_key_type
    errors.add(:base, :invalid_key) if gitolite_public_key && gitolite_public_key.key_type_as_string != 'deploy_key'
  end

  def owner_matches_key
    return if user.nil? || gitolite_public_key.nil?

    errors.add(:base, :invalid_user) if user != gitolite_public_key.user
  end
end
