FactoryGirl.define do

  factory :user do |user|
    user.sequence(:login)     { |n| "user#{n}" }
    user.sequence(:firstname) { |n| "User#{n}" }
    user.sequence(:lastname)  { |n| "Test#{n}" }
    user.sequence(:mail)      { |n| "user#{n}@awesome.com" }
    user.language             "fr"
    user.hashed_password      "66eb4812e268747f89ec309178e2ea50410653fb"
    user.salt                 "5abd4e59ac0d483daf2f68d3b6544ff3"
  end

end
