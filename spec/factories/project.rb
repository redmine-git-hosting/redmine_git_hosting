FactoryGirl.define do

  factory :project do |project|
    project.sequence(:identifier)   { |n| "project#{n}"}
    project.sequence(:name)         { |n| "Project#{n}"}
  end

end
