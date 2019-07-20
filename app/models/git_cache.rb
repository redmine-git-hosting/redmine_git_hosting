class GitCache < ActiveRecord::Base
  include Redmine::SafeAttributes

  CACHE_ADAPTERS = [%w[Database database],
                    %w[Memcached memcached],
                    %w[Redis redis]].freeze

  ## Attributes
  safe_attributes 'repo_identifier', 'command', 'command_output'

  ## Validations
  validates :repo_identifier, presence: true
  validates :command,         presence: true
  validates :command_output,  presence: true

  class << self
    def adapters
      CACHE_ADAPTERS.map(&:last)
    end
  end
end
