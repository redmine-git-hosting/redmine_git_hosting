class GithubComment < ActiveRecord::Base
  unloadable

  belongs_to :journal

  validates :github_id,  :presence => true
  validates :journal_id, :presence => true, :uniqueness => { :scope => :github_id }
end
