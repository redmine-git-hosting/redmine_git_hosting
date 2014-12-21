FactoryGirl.define do

  factory :repository_git_extra do |f|
    f.git_http        0
    f.default_branch  "master"
    f.association     :repository, :factory => :repository_gitolite
  end

end
