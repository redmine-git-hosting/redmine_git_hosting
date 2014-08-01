FactoryGirl.define do

  factory :repository_mirror do |f|
    f.sequence(:url) { |n| "ssh://host.xz/path/to/repo#{n}.git" }
    f.push_mode      0
    f.association    :repository, :factory => :repository_git
  end

end
