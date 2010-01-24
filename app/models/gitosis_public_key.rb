class GitosisPublicKey < ActiveRecord::Base

  STATUS_ACTIVE = 1
  STATUS_LOCKED = 0

  belongs_to :user
  validates_uniqueness_of :title, :scope => :user_id
  validates_uniqueness_of :identifier, :score => :user_id
  validates_presence_of :title, :key, :identifier
  
  named_scope :active, {:conditions => {:active => GitosisPublicKey::STATUS_ACTIVE}}
  named_scope :inactive, {:conditions => {:active => GitosisPublicKey::STATUS_LOCKED}}
  
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
    self.identifier ||= "#{self.user.login.underscore}-#{self.title.underscore}-#{self.id}".gsub(/[^0-9a-zA-Z-_]/,'_')
  end
    
  def to_s ; title ; end
  
end
