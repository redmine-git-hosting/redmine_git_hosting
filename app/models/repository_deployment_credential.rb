class RepositoryDeploymentCredential < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE   = true
  STATUS_INACTIVE = false

  VALID_PERMS  = [ "R", "RW+" ]
  DEFAULT_PERM = "RW+"

  attr_accessible :perm, :active

  ## Relations
  belongs_to :repository
  belongs_to :gitolite_public_key
  belongs_to :user

  ## Validations
  validates :repository_id,          :presence => true,
                                     :uniqueness => { :scope => :gitolite_public_key_id }

  validates :gitolite_public_key_id, :presence => true
  validates :user_id,                :presence => true
  validates :perm,                   :presence => true,
                                     :inclusion => { :in => VALID_PERMS }

  validates_associated :repository
  validates_associated :gitolite_public_key
  validates_associated :user

  validate :correct_key_type, :owner_matches_key

  ## Scopes
  scope :active,   -> { where active: STATUS_ACTIVE }
  scope :inactive, -> { where active: STATUS_LOCKED }

  ## Callbacks
  after_commit ->(obj) { obj.update_permissions }, on: :create
  after_commit ->(obj) { obj.update_permissions }, on: :update
  after_commit ->(obj) { obj.update_permissions }, on: :destroy


  def to_s
    "#{repository.identifier}-#{gitolite_public_key.identifier} : #{perm}"
  end


  # Provide a role-like interface.
  # Support :commit_access and :view_changesets
  @@equivalence = nil
  def allowed_to?( cred )
    @@equivalence ||= {
      :view_changesets => ["R", "RW+"],
      :commit_access   => ["RW+"]
    }
    return false unless honored?

    # Deployment Credentials equivalence matrix
    return false unless @@equivalence[cred] && @@equivalence[cred].index(perm)
    true
  end


  # Deployment Credentials ignored unless created by someone who still has permission to create them
  def honored?
    user.admin? || user.allowed_to?(:create_deployment_keys, repository.project)
  end


  protected


  def update_permissions
    RedmineGitolite::GitHosting.logger.info { "Update deploy keys for repository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => repository.id })
  end


  private


  def correct_key_type
    if gitolite_public_key && gitolite_public_key.key_type != GitolitePublicKey::KEY_TYPE_DEPLOY
      errors.add(:base, "Public Key Must Be a Deployment Key")
    end
  end


  def owner_matches_key
    return if user.nil? || gitolite_public_key.nil?
    if user != gitolite_public_key.user
      errors.add(:base, "Credential owner cannot be different than owner of Key.")
    end
  end

end
