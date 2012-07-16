class RepositoryPostReceiveUrl < ActiveRecord::Base
  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0

  belongs_to :project

  attr_accessible :url, :mode, :active

  validates_uniqueness_of :url, :scope => [:project_id]
  validates_presence_of :project_id, :url
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates_associated :project

  named_scope :active, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_ACTIVE}}
  named_scope :inactive, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_INACTIVE}}

  validates_inclusion_of :mode, :in => [:github, :get]
  def mode
    read_attribute(:mode).to_sym rescue nil
  end
  def mode= (value)
    write_attribute(:mode, (value.to_sym && value.to_sym.to_s rescue nil))
  end

  def to_s
    return File.join("#{project.identifier}-#{url}")
  end
end
