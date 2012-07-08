module GitHosting
	module Patches
		module ProjectPatch
			def self.included(base)
				base.class_eval do
					unloadable

                        		named_scope :archived, { :conditions => {:status => "#{Project::STATUS_ARCHIVED}"}}
                        		named_scope :active_or_archived, { :conditions => "status=#{Project::STATUS_ACTIVE} OR status=#{Project::STATUS_ARCHIVED}" }

                            		# initialize association from project -> repository mirrors
					has_many :repository_mirrors, :dependent => :destroy

                            		# initialize association from project -> repository post receive urls
  					has_many :repository_post_receive_urls, :dependent => :destroy

                        	end
			end
		end
	end
end
