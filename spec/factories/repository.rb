FactoryGirl.define do

  factory :repository, class: 'Repository::Git' do |repository|
    repository.is_default  false
  end

end
