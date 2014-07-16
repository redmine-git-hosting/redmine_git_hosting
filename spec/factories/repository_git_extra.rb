FactoryGirl.define do

  factory :repository_git_extra do |git_extra|
    git_extra.git_http        0
    git_extra.default_branch  "master"
  end

end
