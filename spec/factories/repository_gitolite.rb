FactoryBot.define do
  factory :repository_gitolite, class: 'Repository::Xitolite' do
    is_default { false }
    association :project
  end
end
