FactoryGirl.define do

  factory :repository_svn, class: 'Repository::Subversion' do |f|
    f.is_default  false
  end

end
