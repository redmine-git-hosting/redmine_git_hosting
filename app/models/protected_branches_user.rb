class ProtectedBranchesUser < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :protected_branch, class_name: 'RepositoryProtectedBranche'
  belongs_to :user
end
