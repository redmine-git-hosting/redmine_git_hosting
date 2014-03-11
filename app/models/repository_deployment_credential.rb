class RepositoryDeploymentCredential < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0

  belongs_to :repository
  belongs_to :gitolite_public_key
  belongs_to :user

  attr_accessible :perm, :active

  validates_presence_of :repository, :gitolite_public_key, :user, :perm

  validate :correct_key_type, :correct_perm_type, :no_duplicate_creds, :owner_matches_key

  scope :active,   -> { where active: STATUS_ACTIVE }
  scope :inactive, -> { where active: STATUS_LOCKED }

  after_commit ->(obj) { obj.update_permissions }, on: :create
  after_commit ->(obj) { obj.update_permissions }, on: :update
  after_commit ->(obj) { obj.update_permissions }, on: :destroy


  def self.valid_perms
    ["R", "RW+"]
  end


  def self.default_perm
    "RW+"
  end


  def to_s
    return File.join("Deploy Key: #{repository.identifier}-#{gitolite_public_key.identifier}: #{mode.to_s}")
  end


  def perm= (value)
    write_attribute(:perm, (value.upcase rescue nil))
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


  def correct_key_type
    if gitolite_public_key && gitolite_public_key.key_type != GitolitePublicKey::KEY_TYPE_DEPLOY
      errors.add(:base, "Public Key Must Be a Deployment Key")
    end
  end


  def correct_perm_type
    if !self.class.valid_perms.index(perm)
      errors.add(:perm, "must be one of #{self.class.valid_perms.join(',')}")
    end
  end


  def owner_matches_key
    return if user.nil? || gitolite_public_key.nil?
    if user != gitolite_public_key.user
      errors.add(:base, "Credential owner cannot be different than owner of Key.")
    end
  end


  def no_duplicate_creds
    return if !new_record? || repository.nil? || gitolite_public_key.nil?
    repository.repository_deployment_credentials.each do |cred|
      if cred.gitolite_public_key == gitolite_public_key
        errors.add(:base, "This Public Key has already been used in a Deployment Credential for this repository.")
      end
    end
  end

end
