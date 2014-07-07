FactoryGirl.define do

  factory :repository_mirror do |mirror|
    mirror.sequence(:url) { |n| "ssh://host.xz/path/to/repo#{n}.git" }
    mirror.push_mode 0
  end

end
