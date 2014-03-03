require 'base64'

include GitolitePublicKeysHelper

class GitolitePublicKey < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE = 1
  STATUS_LOCKED = 0

  KEY_TYPE_USER = 0
  KEY_TYPE_DEPLOY = 1

  DEPLOY_PSEUDO_USER = "deploy_key"

  # These two constants are related -- don't change one without the other
  KEY_FORMATS = ['ssh-rsa', 'ssh-dss']
  KEY_NUM_COMPONENTS = [3, 5]

  belongs_to :user
  has_many   :repository_deployment_credentials, :dependent => :destroy

  scope :active,   -> { where active: STATUS_ACTIVE }
  scope :inactive, -> { where active: STATUS_LOCKED }

  scope :user_key,   -> { where key_type: KEY_TYPE_USER }
  scope :deploy_key, -> { where key_type: KEY_TYPE_DEPLOY }

  validates_presence_of   :title, :identifier, :key, :key_type
  validates_inclusion_of  :key_type, :in => [KEY_TYPE_USER, KEY_TYPE_DEPLOY]

  validates_uniqueness_of :title,      :scope => :user_id
  validates_uniqueness_of :identifier, :scope => :user_id

  validates_associated :repository_deployment_credentials

  validate :has_not_been_changed
  validate :key_format_and_uniqueness

  before_validation :set_identifier
  before_validation :strip_whitespace
  before_validation :remove_control_characters

  after_commit      :add_ssh_key, :on => :create


  @@myregular = /^(.*)@redmine_\d*_\d*(.pub)?$/
  def self.ident_to_user_token(identifier)
    result = @@myregular.match(identifier)
    (result != nil) ? result[1] : nil
  end


  def self.by_user(user)
    where("user_id = ?", user.id)
  end


  def set_identifier
    self.identifier ||=
      begin
        my_time = Time.now
        time_tag = "#{my_time.to_i.to_s}_#{my_time.usec.to_s}"
        case key_type
          when KEY_TYPE_USER
            # add "redmine_" as a prefix to the username, and then the current date
            # this helps ensure uniqueness of each key identifier
            #
            # also, it ensures that it is very, very unlikely to conflict with any
            # existing key name if gitolite config is also being edited manually
            "redmine_#{self.user.login.underscore}".gsub(/[^0-9a-zA-Z\-]/, '_') << "@redmine_" << "#{time_tag}".gsub(/[^0-9a-zA-Z\-]/, '_')
          when KEY_TYPE_DEPLOY
            # add "redmine_deploy_key_" as a prefix, and then the current date
            # to help ensure uniqueness of each key identifier
            "redmine_#{DEPLOY_PSEUDO_USER}_#{time_tag}".gsub(/[^0-9a-zA-Z\-]/, '_') << "@redmine_" << "#{time_tag}".gsub(/[^0-9a-zA-Z\-]/, '_')
          else
            nil
          end
        end
  end


  # Key type checking functions
  def user_key?
    key_type == KEY_TYPE_USER
  end


  def deploy_key?
    key_type == KEY_TYPE_DEPLOY
  end


  # Make sure that current identifier is consistent with current user login.
  # This method explicitly overrides the static nature of the identifier
  def reset_identifier
    # Fix identifier
    self.identifier = nil
    set_identifier

    # Need to override the "never change identifier" constraint
    # Note that Rails 3 has a different calling convention...
    self.save(:validate => false)

    self.identifier
  end


  def to_s
    title
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
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :add_ssh_key, :object => self.user.id })

    if user_key?
      project_list = []
      self.user.projects_by_role.each do |role|
        role[1].each do |project|
          project_list.push(project.id)
        end
      end

      if project_list.length > 0
        RedmineGitolite::GitHosting.logger.info { "Update project to add SSH access : #{project_list.uniq}" }
        RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_projects, :object => project_list.uniq })
      end
    end
  end


  # Strip leading and trailing whitespace
  def strip_whitespace
    self.title = title.strip

    # Don't mess with existing keys (since cannot change key text anyway)
    if new_record?
      self.key = key.strip
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


  def has_not_been_changed
    unless new_record?
      %w(identifier key user_id key_type).each do |attribute|
        errors.add(attribute, 'may not be changed') unless changes[attribute].blank?
      end
    end
  end


  def key_format_and_uniqueness
    return if key.blank?

    # First, check that key crypto type is present and of correct form.  Also, decode base64 and see if key
    # crypto type matches.  Note that we ignore presence of comment!
    keypieces = key.match(/^(\S+)\s+(\S+)/)
    if !keypieces || keypieces[1].length > 10  # Probably has key as first component
      errors.add(:key,l(:error_key_needs_two_components))
      return false
    end

    if !(KEY_FORMATS.index(keypieces[1]))
      errors.add(:key,l(:error_key_bad_type, :types => wrap_and_join(KEY_FORMATS, l(:word_or))))
      return false
    end

    # Make sure that key has proper number of characters (divisible by 4) and no more than 2 '='
    if (keypieces[2].length % 4) != 0 || !(keypieces[2].match(/^[a-zA-Z0-9\+\/]+={0,2}$/))
      errors.add(:key, l(:error_key_corrupted))
      return false
    end

    deckey = Base64.decode64(keypieces[2])
    piecearray = []
    while deckey.length >= 4
      length = 0
      deckey.slice!(0..3).bytes do |byte|
        length = length * 256 + byte
      end
      if deckey.length < length
        errors.add(:key, l(:error_key_corrupted))
        return false
      end
      piecearray << deckey.slice!(0..length-1)
    end

    if deckey.length != 0
      errors.add(:key, l(:error_key_corrupted))
      return false
    end

    if piecearray[0] != keypieces[1]
      puts YAML::dump(keypieces[1])
      puts YAML::dump(piecearray[0])

      # errors.add(:key, l(:error_key_type_mismatch, :type1 => keypieces[1], :type2 => piecearray[0]))
      return false
    end

    if piecearray.length != KEY_NUM_COMPONENTS[KEY_FORMATS.index(piecearray[0])]
      errors.add(:key, l(:error_key_corrupted))
      return false
    end

    # First version of uniqueness check -- simply check all keys...

    # Check against the gitolite administrator key file (owned by noone).
    allkeys = [GitolitePublicKey.new({ :user => nil, :key => %x[cat '#{RedmineGitolite::ConfigRedmine.get_setting(:gitolite_ssh_public_key)}'] })]

    # Check all active keys
    allkeys += (GitolitePublicKey.active.all)

    allkeys.each do |existingkey|
      next if existingkey.id == id
      existingpieces = existingkey.key.match(/^(\S+)\s+(\S+)/)
      if existingpieces && (existingpieces[2] == keypieces[2])
        # Hm.... have a duplicate key!
        if existingkey.user == User.current
          errors.add(:key, l(:error_key_in_use_by_you, :name => existingkey.title))
          return false
        elsif User.current.admin?
          if existingkey.user
            errors.add(:key, l(:error_key_in_use_by_other, :login => existingkey.user.login, :name => existingkey.title))
            return false
          else
            errors.add(:key, l(:error_key_in_use_by_admin))
            return false
          end
        else
          errors.add(:key, l(:error_key_in_use_by_someone))
          return false
        end
      end
    end

  end

end
