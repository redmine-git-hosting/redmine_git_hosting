class RepositoryGitNotification < ActiveRecord::Base
  unloadable

  ## Attributes
  attr_accessible :prefix, :sender_address, :include_list, :exclude_list

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,  presence: true, uniqueness: true
  validates :sender_address, format: { with: RedmineGitHosting::Validators::EMAIL_REGEX, allow_blank: true }

  validate :validate_mailing_list

  ## Serializations
  serialize :include_list, Array
  serialize :exclude_list, Array

  ## Callbacks
  before_validation :remove_blank_items


  private


    def remove_blank_items
      self.include_list = include_list.select { |mail| !mail.blank? }
      self.exclude_list = exclude_list.select { |mail| !mail.blank? }
    end


    def validate_mailing_list
      include_list.each do |item|
        errors.add(:include_list, :invalid) unless RedmineGitHosting::Validators.valid_email?(item)
      end

      exclude_list.each do |item|
        errors.add(:exclude_list, :invalid) unless RedmineGitHosting::Validators.valid_email?(item)
      end

      intersection = include_list & exclude_list
      errors.add(:base, :invalid) if intersection.length.to_i > 0
    end

end
