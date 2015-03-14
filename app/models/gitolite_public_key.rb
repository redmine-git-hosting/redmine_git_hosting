class GitolitePublicKey < ActiveRecord::Base
  unloadable

  TITLE_LENGTH_LIMIT = 60

  KEY_TYPE_USER   = 0
  KEY_TYPE_DEPLOY = 1

  DEPLOY_PSEUDO_USER = 'deploy_key'

  ## Attributes
  attr_accessible :title, :key, :key_type, :delete_when_unused

  ## Relations
  belongs_to :user
  has_many   :repository_deployment_credentials, dependent: :destroy

  ## Validations
  validates :user_id,     presence: true

  validates :title,       presence: true, uniqueness: { case_sensitive: false, scope: :user_id },
                          length: { maximum: TITLE_LENGTH_LIMIT }, format: /\A[a-z0-9_\-]*\z/i

  validates :identifier,  presence: true, uniqueness: { case_sensitive: false, scope: :user_id }
  validates :key,         presence: true
  validates :key_type,    presence: true, numericality: { only_integer: true },
                          inclusion: { in: [KEY_TYPE_USER, KEY_TYPE_DEPLOY] }

  validate :has_not_been_changed
  validate :key_correctness
  validate :key_uniqueness

  ## Scopes
  scope :user_key,   -> { where(key_type: KEY_TYPE_USER) }
  scope :deploy_key, -> { where(key_type: KEY_TYPE_DEPLOY) }

  ## Callbacks
  before_validation :strip_whitespace
  before_validation :remove_control_characters

  before_validation :set_identifier
  before_validation :set_fingerprint


  def key_type_as_string
    user_key? ? 'user_key' : 'deploy_key'
  end


  def to_s
    title
  end


  def data_for_destruction
    { title: identifier , key: key, location: location, owner: owner }
  end


  # Returns the path to this key under the gitolite keydir
  # resolves to <user.gitolite_identifier>/<location>/<owner>.pub
  #
  # tile: test-key
  # identifier: redmine_admin_1@redmine_test_key
  # identifier: redmine_admin_1@redmine_deploy_key_1
  #
  #
  # keydir/
  # ├── redmine_git_hosting
  # │   └── redmine_admin_1
  # │       ├── redmine_test_key
  # │       │   └── redmine_admin_1.pub
  # │       ├── redmine_deploy_key_1
  # │       │   └── redmine_admin_1.pub
  # │       └── redmine_deploy_key_2
  # │           └── redmine_admin_1.pub
  # └── redmine_gitolite_admin_id_rsa.pub
  #
  #
  # The root folder for this user is the user's identifier
  # for logical grouping of their keys, which are organized
  # by their title in subfolders.
  #
  # This is due to the new gitolite multi-keys organization
  # using folders. See http://gitolite.com/gitolite/users.html
  def gitolite_path
    File.join('keydir', RedmineGitHosting::Config.gitolite_key_subdir, user.gitolite_identifier, location, owner) + '.pub'
  end


  # Make sure that current identifier is consistent with current user login.
  # This method explicitly overrides the static nature of the identifier
  def reset_identifiers
    # Fix identifier
    self.identifier = nil
    self.fingerprint = nil

    set_identifier
    set_fingerprint

    # Need to override the "never change identifier" constraint
    self.save(validate: false)
  end


  # Key type checking functions
  def user_key?
    key_type == KEY_TYPE_USER
  end


  def deploy_key?
    key_type == KEY_TYPE_DEPLOY
  end


  def owner
    identifier.split('@')[0]
  end


  def location
    identifier.split('@')[1]
  end


  private


    # Strip leading and trailing whitespace
    # Don't mess with existing keys (since cannot change key text anyway)
    #
    def strip_whitespace
      return if !new_record?
      self.title = title.strip rescue ''
      self.key   = key.strip rescue ''
    end


    # Remove control characters from key
    # Don't mess with existing keys (since cannot change key text anyway)
    #
    def remove_control_characters
      return if !new_record?
      self.key = RedmineGitHosting::Utils.sanitize_ssh_key(key)
    end


    # Returns the unique identifier for this key based on the key_type
    #
    # For user public keys, this simply is the user's gitolite_identifier.
    # For deployment keys, we use an incrementing number.
    #
    def set_identifier
      return nil if user_id.nil?
      if user_key?
        set_identifier_for_user_key
      elsif deploy_key?
        set_identifier_for_deploy_key
      end
    end


    def set_identifier_for_user_key
      tag = self.title.gsub(/[^0-9a-zA-Z]/, '_')
      self.identifier ||= [ user.gitolite_identifier, '@', 'redmine_', tag ].join
    end


    def set_identifier_for_deploy_key
      self.identifier ||= deploy_key_identifier
    end


    # Fix https://github.com/jbox-web/redmine_git_hosting/issues/288
    # Getting user deployment keys count is not sufficient to assure uniqueness of
    # deployment key identifier. So we need an 'external' counter to increment the global count
    # while a key with this identifier exists.
    #
    def deploy_key_identifier
      count = 0
      begin
        key_id = generate_deploy_key_identifier(count)
        count += 1
      end while user.gitolite_public_keys.deploy_key.map(&:owner).include?(key_id.split('@')[0])
      key_id
    end


    def generate_deploy_key_identifier(count)
      key_count = user.gitolite_public_keys.deploy_key.length + 1 + count
      [ user.gitolite_identifier, '_', DEPLOY_PSEUDO_USER, '_', key_count, '@', 'redmine_', DEPLOY_PSEUDO_USER, '_', key_count ].join
    end


    def set_fingerprint
      begin
        self.fingerprint = RedmineGitHosting::Utils.ssh_fingerprint(key)
      rescue RedmineGitHosting::Error::InvalidSshKey => e
        errors.add(:key, :corrupted)
      end
    end


    def has_not_been_changed
      return if new_record?
      %w(identifier key user_id key_type title fingerprint).each do |attribute|
        method = "#{attribute}_changed?"
        errors.add(attribute, :cannot_change) if self.send(method)
      end
    end


    # Test correctness of fingerprint from output
    # and general ssh-(r|d|ecd)sa <key> <id> structure
    #
    def key_correctness
      return false if key.nil?
      (key.match(/^(\S+)\s+(\S+)/)) && (fingerprint =~ /^(\w{2}:?)+$/i)
    end


    def key_uniqueness
      return if !new_record?
      existing = GitolitePublicKey.find_by_fingerprint(fingerprint)
      if existing
        if existing.user == User.current
          errors.add(:key, :taken_by_you, name: existing.title)
        elsif User.current.admin?
          errors.add(:key, :taken_by_other, login: existing.user.login, name: existing.title)
        else
          errors.add(:key, :taken_by_someone)
        end
      end
    end

end
