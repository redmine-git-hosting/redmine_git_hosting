class GitCache < ActiveRecord::Base
  unloadable

  attr_accessible :command, :command_output, :repo_identifier
end
