require 'uri'

class RepositoryPostReceiveUrl < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE   = true
  STATUS_INACTIVE = false

  attr_accessible :url, :mode, :active, :use_triggers, :triggers, :split_payloads

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


  def mode
    read_attribute(:mode).to_sym
  end


  def mode= (value)
    write_attribute(:mode, value.to_s)
  end


  def needs_push(payloads)
    return false if payloads.empty?
    return payloads if !use_triggers
    return payloads if triggers.empty?

    new_payloads = []

    payloads.each do |payload|
      data = refcomp_parse(payload[:ref])
      if data[:type] == 'heads' && triggers.include?(data[:name])
        new_payloads.push(payload)
      end
    end

    if new_payloads.empty?
      return false
    else
      return new_payloads
    end
  end


  private


  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip
  end

end
