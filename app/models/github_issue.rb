class GithubIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue

  validates_uniqueness_of :github_id, :scope => :issue_id
end
