FactoryGirl.define do

  factory :repository_svn, :class => 'Repository::Subversion' do |repository|
    repository.is_default  false
  end

end
