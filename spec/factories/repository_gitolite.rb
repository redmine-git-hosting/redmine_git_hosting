FactoryGirl.define do

  factory :repository_gitolite, class: 'Repository::Xitolite' do |f|
    f.is_default  false
    f.association :project
  end

end
