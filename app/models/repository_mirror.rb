class RepositoryMirror < ActiveRecord::Base
	STATUS_ACTIVE = 1
	STATUS_INACTIVE = 0

	belongs_to :project

	validates_uniqueness_of :url, :scope => [:project_id]
	validates_presence_of :project_id, :private_key, :url

	validates_associated :project

	named_scope :active, {:conditions => {:active => RepositoryMirror::STATUS_ACTIVE}}
	named_scope :inactive, {:conditions => {:active => RepositoryMirror::STATUS_INACTIVE}}

	def to_s
		return File.join("#{project.identifier}-#{id}.pkey")
	end

end
