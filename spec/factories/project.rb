FactoryGirl.define do

  factory :project do |f|
    f.sequence(:identifier)   { |n| "project#{n}" }
    f.sequence(:name)         { |n| "Project#{n}" }
  end

end
