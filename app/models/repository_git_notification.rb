class RepositoryGitNotification < ActiveRecord::Base
  unloadable

  VALID_EMAIL_REGEX  = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,  :presence => true
  validates :sender_address, :format => { :with => VALID_EMAIL_REGEX, :allow_blank => true }

  validate :validate_mailing_list

  ## Serializations
  serialize :include_list, Array
  serialize :exclude_list, Array

  ## Callbacks
  after_commit ->(obj) { obj.update_repository }, :on => :create
  after_commit ->(obj) { obj.update_repository }, :on => :update
  after_commit ->(obj) { obj.update_repository }, :on => :destroy


  protected


  def update_repository
    RedmineGitolite::GitHosting.logger.info { "Rebuild mailing list for respository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite(:update_repository, repository.id)
  end


  private


  def validate_mailing_list
    include_list.each do |item|
      errors.add(:include_list, 'not a valid email') unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    end

    exclude_list.each do |item|
      errors.add(:exclude_list, 'not a valid email') unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    end

    intersection = include_list & exclude_list
    if intersection.length.to_i > 0
      errors.add(:repository_git_notification, 'the same address is defined twice')
    end
  end


end
