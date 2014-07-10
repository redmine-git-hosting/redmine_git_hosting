class GithubIssue < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :issue

  ## Validations
  validates :github_id, :presence => true
  validates :issue_id,  :presence => true, :uniqueness => { :scope => :github_id }
end
