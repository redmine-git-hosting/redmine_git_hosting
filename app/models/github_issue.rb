class GithubIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue

  validates :github_id, :presence => true
  validates :issue_id,  :presence => true, :uniqueness => { :scope => :github_id }
end
