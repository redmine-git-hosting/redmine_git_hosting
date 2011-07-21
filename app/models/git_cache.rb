class GitCache < ActiveRecord::Base
	attr_accessible :command, :command_output, :proj_identifier
end
