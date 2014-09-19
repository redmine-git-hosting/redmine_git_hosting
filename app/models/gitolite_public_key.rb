class GitolitePublicKey < ActiveRecord::Base
  unloadable

  TITLE_LENGTH_LIMIT = 60

  KEY_TYPE_USER   = 0
  KEY_TYPE_DEPLOY = 1

  DEPLOY_PSEUDO_USER = "deploy_key"

  ## Attributes
  attr_accessible :title, :key, :key_type, :delete_when_unused

  ## Relations
  belongs_to :user
  has_many   :repository_deployment_credentials, :dependent => :destroy

  ## Validations
  validates :user_id,     :presence => true

  validates :title,       :presence => true, :uniqueness => { :case_sensitive => false, :scope => :user_id },
                          :length => { :maximum => TITLE_LENGTH_LIMIT }, :format => /\A[a-z0-9_\-]*\z/i

  validates :identifier,  :presence => true, :uniqueness => { :case_sensitive => false, :scope => :user_id }

  validates :key,         :presence => true

  validates :key_type,    :presence => true,
                          :numericality => { :only_integer => true },
                          :inclusion => { :in => [KEY_TYPE_USER, KEY_TYPE_DEPLOY] }

  validate :has_not_been_changed
  validate :key_correctness
  validate :key_uniqueness

  ## Scopes
  scope :user_key,   -> { where key_type: KEY_TYPE_USER }
  scope :deploy_key, -> { where key_type: KEY_TYPE_DEPLOY }

  ## Callbacks
  before_validation :strip_whitespace
  before_validation :remove_control_characters

  before_validation :set_identifier
  before_validation :set_fingerprint

  after_commit ->(obj) { obj.add_ssh_key },     :on => :create
  after_commit ->(obj) { obj.destroy_ssh_key }, :on => :destroy


  def self.by_user(user)
    where("user_id = ?", user.id)
  end


  def to_s
    title
  end


  def to_yaml
    { :title => self.identifier , :key => self.key, :location => self.location, :owner => self.owner }
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
    File.join('keydir', RedmineGitolite::GitoliteWrapper.gitolite_key_subdir, self.user.gitolite_identifier, self.location, self.owner) + '.pub'
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
    self.save(:validate => false)
  end


  # Key type checking functions
  def user_key?
    key_type == KEY_TYPE_USER
  end


  def deploy_key?
    key_type == KEY_TYPE_DEPLOY
  end


  def owner
    self.identifier.split('@')[0]
  end


  def location
    self.identifier.split('@')[1]
  end


  protected


  def add_ssh_key
    RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has added a SSH key" }
    RedmineGitolite::GitHosting.resync_gitolite(:add_ssh_key, self.id)
  end


  def destroy_ssh_key
    RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has deleted a SSH key" }
    RedmineGitolite::GitHosting.resync_gitolite(:delete_ssh_key, self.to_yaml)
  end


  private


  # Strip leading and trailing whitespace
  def strip_whitespace
    self.title = title.strip rescue ''

    # Don't mess with existing keys (since cannot change key text anyway)
    if new_record?
      self.key = key.strip rescue ''
    end
  end


  # Remove control characters from key
  def remove_control_characters
    # Don't mess with existing keys (since cannot change key text anyway)
    return if !new_record?

    # First -- let the first control char or space stand (to divide key type from key)
    # Really, this is catching a special case in which there is a \n between type and key.
    # Most common case turns first space back into space....
    self.key = key.sub(/[ \r\n\t]/, ' ')

    # Next, if comment divided from key by control char, let that one stand as well
    # We can only tell this if there is an "=" in the key. So, won't help 1/3 times.
    self.key = key.sub(/=[ \r\n\t]/, '= ')

    # Delete any remaining control characters....
    self.key = key.gsub(/[\a\r\n\t]/, '').strip
  end


  # Returns the unique identifier for this key based on the key_type
  #
  # For user public keys, this simply is the user's gitolite_identifier.
  # For deployment keys, we use an incrementing number.
  def set_identifier
    if !self.user_id.nil?
      key_count = GitolitePublicKey.by_user(self.user).deploy_key.length + 1

      case key_type
        when KEY_TYPE_USER
          tag = self.title.gsub(/[^0-9a-zA-Z]/, '_')
          self.identifier ||= [ self.user.gitolite_identifier, '@', 'redmine_', tag ].join

        when KEY_TYPE_DEPLOY
          self.identifier ||= [ self.user.gitolite_identifier, '_', DEPLOY_PSEUDO_USER, '_', key_count, '@', 'redmine_', DEPLOY_PSEUDO_USER, '_', key_count ].join
      end
    else
      nil
    end
  end


  def set_fingerprint
    file = Tempfile.new('keytest')
    file.write(self.key)
    file.close

    begin
      output = RedmineGitolite::GitHosting.capture('ssh-keygen', ['-l', '-f', file.path])
      if output
        self.fingerprint = output.split[1]
      end
    rescue RedmineGitolite::GitHosting::GitHostingException => e
      errors.add(:key, l(:error_key_corrupted))
    ensure
      file.unlink
    end
  end


  def has_not_been_changed
    return if new_record?

    valid = true

    %w(identifier key user_id key_type title fingerprint).each do |attribute|
      method = "#{attribute}_changed?"
      if self.send(method)
        errors.add(attribute, 'cannot be changed')
        valid = false
      end
    end

    return valid
  end


  def key_correctness
    return false if self.key.nil?
    # Test correctness of fingerprint from output
    # and general ssh-(r|d|ecd)sa <key> <id> structure
    (self.key.match(/^(\S+)\s+(\S+)/)) && (self.fingerprint =~ /^(\w{2}:?)+$/i)
  end


  def key_uniqueness
    return if !new_record?

    existing = GitolitePublicKey.find_by_fingerprint(self.fingerprint)

    if existing
      # Hm.... have a duplicate key!
      if existing.user == User.current
        errors.add(:key, l(:error_key_in_use_by_you, :name => existing.title))
        return false
      elsif User.current.admin?
        errors.add(:key, l(:error_key_in_use_by_other, :login => existing.user.login, :name => existing.title))
        return false
      else
        errors.add(:key, l(:error_key_in_use_by_someone))
        return false
      end
    end

    return true
  end

end
