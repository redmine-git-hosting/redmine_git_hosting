class GitolitePublicKey < ActiveRecord::Base
  STATUS_ACTIVE = true
  STATUS_LOCKED = false

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
    # TODO: some better naming, id is set long AFTER this method is called. Maybe timestamp?
    self.identifier ||= "#{self.user.login.underscore}@#{self.title.underscore}".gsub(/[^0-9a-zA-Z-_@]/,'_')
  end
    
  def to_s ; title ; end
  
end
