class RepositoryPostReceiveUrl < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0

  belongs_to :repository

  attr_accessible :url, :mode, :active

  validates_uniqueness_of :url, :scope => [:repository_id]
  validates_presence_of :repository_id
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates_associated :repository

  before_validation :strip_whitespace

  if Rails::VERSION::MAJOR >= 3 && Rails::VERSION::MINOR >= 1
    scope :active, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_ACTIVE}}
    scope :inactive, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_INACTIVE}}
  else
    named_scope :active, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_ACTIVE}}
    named_scope :inactive, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_INACTIVE}}
  end

  validates_inclusion_of :mode, :in => [:github, :get]

  def mode
    read_attribute(:mode).to_sym rescue nil
  end

  def mode= (value)
    write_attribute(:mode, (value.to_sym && value.to_sym.to_s rescue nil))
  end

  def to_s
    return File.join("#{repository.project.identifier}-#{url}")
  end

  protected

  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip
  end

end
