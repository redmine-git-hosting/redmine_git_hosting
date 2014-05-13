FactoryGirl.define do

  factory :repository_git_config_key do |git_config_key|
    git_config_key.key    'hookfoo.foo'
    git_config_key.value  'bar'
  end

end
