class GitCache < ActiveRecord::Base
  unloadable

  ## Attributes
  attr_accessible :repo_identifier, :command, :command_output
end
