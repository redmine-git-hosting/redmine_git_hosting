require 'digest/sha1'

class RepositoryGitExtra < ActiveRecord::Base
  unloadable

  belongs_to :repository, :class_name => 'Repository', :foreign_key => 'repository_id'

  validates_associated :repository

  attr_accessible :id, :repository_id, :key, :git_http, :git_daemon, :git_notify, :default_branch

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
    write_attribute(:git_daemon, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_daemon_by_default, true) ? 1 : 0)
    write_attribute(:git_notify, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_by_default, true) ? 1 : 0)
    write_attribute(:default_branch, 'master')
  end

end
