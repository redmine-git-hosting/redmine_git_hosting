require 'uri'

class RepositoryPostReceiveUrl < ActiveRecord::Base

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
  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  ## Callbacks
  before_validation :strip_whitespace
  before_validation :remove_blank_triggers


  def mode
    read_attribute(:mode).to_sym
  end


  def mode=(value)
    write_attribute(:mode, value.to_s)
  end


  def github_mode?
    mode == :github
  end


  private


    # Strip leading and trailing whitespace
    def strip_whitespace
      self.url = url.strip rescue ''
    end


    # Remove blank entries in triggers
    def remove_blank_triggers
      self.triggers = triggers.select { |t| !t.empty? }
    end

end
