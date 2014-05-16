require 'uri'

class RepositoryPostReceiveUrl < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE   = true
  STATUS_INACTIVE = false

  attr_accessible :url, :mode, :active, :use_triggers, :triggers

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, :presence => true

  ## Only allow HTTP(s) format
  validates :url, :presence   => true,
                  :uniqueness => { :case_sensitive => false, :scope => :repository_id },
                  :format     => { :with => URI::regexp(%w(http https)) }

  validates :mode, :presence => true, :inclusion => { :in => [:github, :get] }

  validates_associated :repository

  ## Serializations
  serialize :triggers, Array

  ## Scopes
  scope :active,   -> { where active: STATUS_ACTIVE }
  scope :inactive, -> { where active: STATUS_INACTIVE }

  ## Callbacks
  before_validation :strip_whitespace

  include GitoliteHooksHelper


  def to_s
    return "#{repository.project.identifier}-#{url}"
  end


  def mode
    read_attribute(:mode).to_sym rescue nil
  end


  def mode= (value)
    write_attribute(:mode, (value.to_sym && value.to_sym.to_s rescue nil))
  end


  def needs_push(payloads)
    return true if !use_triggers
    return true if payloads.empty?
    return true if triggers.empty?

    collected_head = []

    payloads.each do |payload|
      data = refcomp_parse(payload[:ref])
      if data[:type] == 'heads'
        collected_head.push(data[:name])
      end
    end

    intersection = collected_head & triggers
    if intersection.length.to_i > 0
      return true
    else
      return false
    end
  end


  private


  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip
  end

end
