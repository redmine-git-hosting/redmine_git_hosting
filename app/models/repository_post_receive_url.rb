# frozen_string_literal: true

require 'uri'

class RepositoryPostReceiveUrl < ActiveRecord::Base
  include Redmine::SafeAttributes

  ## Attributes
  safe_attributes 'url', 'mode', 'active', 'use_triggers', 'triggers', 'split_payloads'

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true

  # Only allow HTTP(s) format
  validates :url, presence: true,
                  uniqueness: { case_sensitive: false, scope: :repository_id },
                  format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  validates :mode, presence: true, inclusion: { in: %i[github get post] }

  ## Serializations
  serialize :triggers, type: Array

  ## Scopes
  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }
  scope :sorted, -> { order :url }

  ## Callbacks
  before_validation :strip_whitespace
  before_validation :remove_blank_triggers

  def mode
    self[:mode].to_sym
  end

  def mode=(value)
    self[:mode] = value.to_s
  end

  def github_mode?
    mode == :github
  end

  private

  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = begin
      url.strip
    rescue StandardError
      ''
    end
  end

  # Remove blank entries in triggers
  def remove_blank_triggers
    self.triggers = triggers.select(&:present?)
  end
end
