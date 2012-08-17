class GitolitePublicKey < ActiveRecord::Base
    STATUS_ACTIVE = 1
    STATUS_LOCKED = 0

    KEY_TYPE_USER = 0
    KEY_TYPE_DEPLOY = 1

    DEPLOY_PSEUDO_USER = "_deploy_key_"

    belongs_to :user
    validates_uniqueness_of :title, :scope => :user_id
    validates_uniqueness_of :identifier, :scope => :user_id
    validates_presence_of :title, :key, :identifier, :key_type

    has_many :deployment_credentials, :dependent => :destroy
    def validate_associated_records_for_deployment_credentials() end

    named_scope :active, {:conditions => {:active => GitolitePublicKey::STATUS_ACTIVE}}
    named_scope :inactive, {:conditions => {:active => GitolitePublicKey::STATUS_LOCKED}}

    named_scope :user_key, {:conditions => {:key_type => GitolitePublicKey::KEY_TYPE_USER}}
    named_scope :deploy_key, {:conditions => {:key_type => GitolitePublicKey::KEY_TYPE_DEPLOY}}

    validate :has_not_been_changed
    validates_inclusion_of :key_type, :in => [KEY_TYPE_USER, KEY_TYPE_DEPLOY]

    before_validation :set_identifier
    before_validation :remove_control_characters

    def has_not_been_changed
	unless new_record?
	    %w(identifier key user_id key_type).each do |attribute|
		errors.add(attribute, 'may not be changed') unless changes[attribute].blank?
	    end
	end
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
		    "redmine_#{self.user.login.underscore}_#{time_tag}".gsub(/[^0-9a-zA-Z\-]/,'_')
		when KEY_TYPE_DEPLOY
		    # add "redmine_deploy_key_" as a prefix, and then the current date
		    # to help ensure uniqueness of each key identifier
		    "redmine_#{DEPLOY_PSEUDO_USER}_#{time_tag}"
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
	self.save((Rails::VERSION::STRING.split('.')[0].to_i > 2) ? { :validate => false } : false)

	self.identifier
    end

    # Remove control characters from key
    def remove_control_characters
	self.key=key.gsub(/[\a\r\n\t]/,'')
    end

    def to_s ; title ; end

    @@myregular = /^redmine_(.*)_\d*_\d*(.pub)?$/
    def self.ident_to_user_token(identifier)
	result = @@myregular.match(identifier)
	(result!=nil) ? result[1] : nil
    end

    def self.user_to_user_token(user)
	user.login.underscore.gsub(/[^0-9a-zA-Z\-]/,'_')
    end
end
