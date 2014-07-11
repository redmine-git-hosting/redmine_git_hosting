FactoryGirl.define do

  factory :repository_git, :class => 'Repository::Git' do |repository|
    repository.is_default  false
  end

end
