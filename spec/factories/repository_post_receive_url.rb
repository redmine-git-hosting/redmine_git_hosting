FactoryGirl.define do

  factory :repository_post_receive_url do |f|
    f.sequence(:url) { |n| "http://example.com/toto#{n}.php" }
    f.association    :repository, factory: :repository_gitolite
  end

end
