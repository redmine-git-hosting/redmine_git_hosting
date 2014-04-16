class GithubComment < ActiveRecord::Base
  unloadable

  belongs_to :journal

  validates_uniqueness_of :github_id, :scope => :journal_id
end
