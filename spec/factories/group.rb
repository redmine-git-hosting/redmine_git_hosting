FactoryGirl.define do

  factory :group do |f|
    f.sequence(:lastname)  { |n| "GroupTest#{n}" }
  end

end
