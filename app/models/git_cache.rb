class GitCache < ActiveRecord::Base
	attr_accessible :command, :output
end
