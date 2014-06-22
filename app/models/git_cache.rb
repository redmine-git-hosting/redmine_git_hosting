class GitCache < ActiveRecord::Base
  unloadable

  attr_accessible :repo_identifier, :command, :command_output
end
