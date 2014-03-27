class GithubComment < ActiveRecord::Base
  unloadable

  belongs_to :journal
end
