FactoryBot.define do
  factory :repository_deployment_credential do
    perm { 'RW+' }
    association :repository, factory: :repository_gitolite
    association :user
    association :gitolite_public_key
  end
end
