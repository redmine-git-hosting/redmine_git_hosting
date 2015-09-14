FactoryGirl.define do

  factory :repository_mirror do |f|
    f.url          { Faker::Git.ssh_url }
    f.push_mode    0
    f.association  :repository, factory: :repository_gitolite
  end

end
