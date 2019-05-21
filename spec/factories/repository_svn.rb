FactoryBot.define do
  factory :repository_svn, class: 'Repository::Subversion' do
    is_default { false }
  end
end
