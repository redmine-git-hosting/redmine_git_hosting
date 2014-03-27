class GithubIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue
end
