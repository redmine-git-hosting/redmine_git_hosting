class RepositoryPostReceiveUrl < ActiveRecord::Base
  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0

  belongs_to :project

  validates_uniqueness_of :url, :scope => [:project_id]
  validates_presence_of :project_id, :url

  validates_associated :project

  named_scope :active, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_ACTIVE}}
  named_scope :inactive, {:conditions => {:active => RepositoryPostReceiveUrl::STATUS_INACTIVE}}

  def to_s
    return File.join("#{project.identifier}-#{url}")
  end
end
