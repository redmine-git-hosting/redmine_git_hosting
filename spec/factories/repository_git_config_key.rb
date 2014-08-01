FactoryGirl.define do

  factory :repository_git_config_key do |f|
    f.sequence(:key) { |n| "hookfoo.foo#{n}" }
    f.value          'bar'
    f.association    :repository, :factory => :repository_git
  end

end
