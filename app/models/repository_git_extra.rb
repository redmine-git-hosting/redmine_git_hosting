class RepositoryGitExtra < ActiveRecord::Base
  unloadable

  attr_accessible :git_http, :git_daemon, :git_notify, :default_branch

  ## Relations
  belongs_to :repository

  ## Validations
  validates_associated :repository

  ## Callbacks
  after_initialize :set_values


  private


  def set_values
    if self.repository.nil?
      generate
      setup_defaults
    end
  end


  def generate
    if self.key.nil?
      write_attribute(:key, (0...64+rand(64) ).map{65.+(rand(25)).chr}.join)
    end
  end


  def setup_defaults
    write_attribute(:git_http,   RedmineGitolite::ConfigRedmine.get_setting(:gitolite_http_by_default))
    write_attribute(:git_daemon, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_daemon_by_default))
    write_attribute(:git_notify, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_by_default))
    write_attribute(:default_branch, 'master')
  end

end
