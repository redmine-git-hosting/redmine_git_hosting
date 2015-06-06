FactoryGirl.define do

  factory :repository_deployment_credential do |f|
    f.perm        'RW+'
    f.association :repository, factory: :repository_gitolite
    f.association :user
    f.association :gitolite_public_key
  end

end
