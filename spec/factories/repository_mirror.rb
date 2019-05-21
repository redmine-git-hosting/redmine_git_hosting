FactoryBot.define do
  factory :repository_mirror do
    url { Faker::Git.ssh_url }
    push_mode { 0 }
    association :repository, factory: :repository_gitolite
  end
end
