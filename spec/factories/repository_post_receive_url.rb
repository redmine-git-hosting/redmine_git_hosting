FactoryGirl.define do

  factory :repository_post_receive_url do |post_receive_url|
    post_receive_url.sequence(:url) { |n| "http://example.com/toto#{n}.php" }
  end

end
