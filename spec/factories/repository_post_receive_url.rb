FactoryGirl.define do

  factory :repository_post_receive_url do |post_receive_url|
    post_receive_url.url  'http://example.com/toto.php'
  end

end
