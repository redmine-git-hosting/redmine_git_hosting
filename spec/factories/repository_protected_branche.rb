FactoryBot.define do
  factory :repository_protected_branche do
    path { 'master' }
    permissions { 'RW+' }
    association :repository, factory: :repository_gitolite
  end
end
