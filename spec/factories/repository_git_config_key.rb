FactoryGirl.define do

  factory :repository_git_config_key do |git_config_key|
    git_config_key.sequence(:key) { |n| "hookfoo.foo#{n}" }
    git_config_key.value  'bar'
  end

end
