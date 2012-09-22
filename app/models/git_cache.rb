class GitCache < ActiveRecord::Base
    attr_accessible :command, :command_output, :repo_identifier
end
