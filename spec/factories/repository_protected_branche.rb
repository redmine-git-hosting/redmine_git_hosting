FactoryGirl.define do

  factory :repository_protected_branche do |f|
    f.path         'master'
    f.permissions  'RW+'
    f.association  :repository, factory: :repository_gitolite
  end

end
