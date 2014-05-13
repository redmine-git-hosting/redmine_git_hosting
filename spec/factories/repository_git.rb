FactoryGirl.define do

  factory :repository_git, class: 'Repository::Git' do |repository|
    repository.url         'repositories/test.git'
    repository.root_url    'repositories/test.git'
    repository.is_default  true
  end

end
