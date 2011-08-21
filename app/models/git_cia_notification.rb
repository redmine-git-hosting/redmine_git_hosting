class GitCiaNotification < ActiveRecord::Base

	belongs_to :repository

	validates_uniqueness_of :scmid, :scope => [:repository_id]
	validates_presence_of :repository_id, :scmid

	validates_associated :repository

end
