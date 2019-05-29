FactoryBot.define do
  factory :repository_mirror do
    url { 'ssh://git@example.com:22/john_doe/john_doe/john_doe.git' }
    push_mode { 0 }
    association :repository, factory: :repository_gitolite
  end
end
