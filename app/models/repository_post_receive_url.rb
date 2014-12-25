require 'uri'

class RepositoryPostReceiveUrl < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE   = true
  STATUS_INACTIVE = false

  ## Attributes
  attr_accessible :url, :mode, :active, :use_triggers, :triggers, :split_payloads

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true

  # Only allow HTTP(s) format
  validates :url, presence:   true,
                  uniqueness: { case_sensitive: false, scope: :repository_id },
                  format:     { with: URI::regexp(%w(http https)) }

  validates :mode, presence: true, inclusion: { in: [:github, :get] }

  ## Serializations
  serialize :triggers, Array

  ## Scopes
  scope :active,   -> { where(active: STATUS_ACTIVE) }
  scope :inactive, -> { where(active: STATUS_INACTIVE) }

  ## Callbacks
  before_validation :strip_whitespace


  def mode
    read_attribute(:mode).to_sym
  end


  def mode=(value)
    write_attribute(:mode, value.to_s)
  end


  private


    # Strip leading and trailing whitespace
    def strip_whitespace
      self.url = url.strip rescue ''
    end

end
