FactoryGirl.define do

  factory :user do |f|
    f.sequence(:login)     { |n| "user#{n}" }
    f.sequence(:firstname) { |n| "User#{n}" }
    f.sequence(:lastname)  { |n| "Test#{n}" }
    f.sequence(:mail)      { |n| "user#{n}@awesome.com" }
    f.language             'fr'
    f.hashed_password      '66eb4812e268747f89ec309178e2ea50410653fb'
    f.salt                 '5abd4e59ac0d483daf2f68d3b6544ff3'
  end

end
