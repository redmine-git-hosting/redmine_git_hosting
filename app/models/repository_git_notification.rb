class RepositoryGitNotification < ActiveRecord::Base
  unloadable

  belongs_to :repository

  serialize :include_list, Array
  serialize :exclude_list, Array

  validate :validate_mailing_list

  validates_format_of :sender_address, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_blank => true

  after_update  :update_repository
  after_destroy :update_repository


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


  def update_repository
    RedmineGitolite::GitHosting.logger.info "Rebuild mailing list for respository : '#{repository.gitolite_repository_name}'"
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => repository.id })
  end

end
