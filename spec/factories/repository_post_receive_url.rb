FactoryBot.define do
  factory :repository_post_receive_url do
    sequence(:url) { |n| "http://example.com/toto#{n}.php" }
    association    :repository, factory: :repository_gitolite
  end
end
