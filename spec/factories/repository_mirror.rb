FactoryBot.define do
  factory :repository_mirror do
    sequence(:url) { |n| "ssh://git@example.com:22/john_doe/john_doe/john_doe_#{n}.git" }
    push_mode { 0 }
    association :repository, factory: :repository_gitolite
  end
end
