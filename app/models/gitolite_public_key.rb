class GitolitePublicKey < ActiveRecord::Base
	STATUS_ACTIVE = 1
	STATUS_LOCKED = 0

	belongs_to :user
	validates_uniqueness_of :title, :scope => :user_id
	validates_uniqueness_of :identifier, :score => :user_id
	validates_presence_of :title, :key, :identifier

	named_scope :active, {:conditions => {:active => GitolitePublicKey::STATUS_ACTIVE}}
	named_scope :inactive, {:conditions => {:active => GitolitePublicKey::STATUS_LOCKED}}

	validate :has_not_been_changed

	before_validation :set_identifier

	def has_not_been_changed
		unless new_record?
			%w(identifier key user_id).each do |attribute|
				errors.add(attribute, 'may not be changed') unless changes[attribute].blank?
			end
		end
	end

	def set_identifier
		# add "redmine_" as a prefix to the username, and then the current date
		# this helps ensure uniqueness of each key identifier
		#
		# also, it ensures that it is very, very unlikely to conflict with any
		# existing key name if gitolite config is also being edited manually
		self.identifier ||= "redmine_#{self.user.login.underscore}_#{Time.now.to_i.to_s}_#{Time.now.usec.to_s}".gsub(/[^0-9a-zA-Z\-]/,'_')
	end

	def to_s ; title ; end
end
