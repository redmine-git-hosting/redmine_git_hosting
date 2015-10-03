FactoryGirl.define do

  factory :protected_branch_user_member, class: 'ProtectedBranchesMember' do |f|
    f.association  :protected_branch, factory: :repository_protected_branche
    f.association  :principal, factory: :user
  end

  factory :protected_branch_group_member, class: 'ProtectedBranchesMember' do |f|
    f.association  :protected_branch, factory: :repository_protected_branche
    f.association  :principal, factory: :group
  end

end
