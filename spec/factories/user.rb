FactoryBot.define do
  factory :user do
    sequence(:login) { |n| "user#{n}" }
    sequence(:firstname) { |n| "User#{n}" }
    sequence(:lastname) { |n| "Test#{n}" }
    sequence(:mail) { |n| "user#{n}@awesome.com" }
    language { 'fr' }
    hashed_password { '66eb4812e268747f89ec309178e2ea50410653fb' }
    salt { '5abd4e59ac0d483daf2f68d3b6544ff3' }
  end
end
