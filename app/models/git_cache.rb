class GitCache < ActiveRecord::Base
  unloadable

  ## Attributes
  attr_accessible :repo_identifier, :command, :command_output

  ## Validations
  validates :repo_identifier, presence: true
  validates :command,         presence: true
  validates :command_output,  presence: true
end
