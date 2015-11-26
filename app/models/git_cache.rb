class GitCache < ActiveRecord::Base

  CACHE_ADAPTERS = [
    ['Database', 'database'],
    ['Memcached', 'memcached'],
    ['Redis', 'redis']
  ]

  ## Attributes
  attr_accessible :repo_identifier, :command, :command_output

  ## Validations
  validates :repo_identifier, presence: true
  validates :command,         presence: true
  validates :command_output,  presence: true


  class << self

    def adapters
      CACHE_ADAPTERS.map { |a| a.last }
    end

  end

end
