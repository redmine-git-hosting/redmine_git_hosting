FactoryBot.define do
  factory :repository_git_config_key_base, class: 'RepositoryGitConfigKey' do
    sequence(:key) { |n| "hookfoo.foo#{n}" }
    value { 'bar' }
    association :repository, factory: :repository_gitolite
  end

  factory :repository_git_config_key, class: 'RepositoryGitConfigKey::GitConfig' do
    sequence(:key) { |n| "hookfoo.foo#{n}" }
    value { 'bar' }
    type { 'RepositoryGitConfigKey::GitConfig' }
    association :repository, factory: :repository_gitolite
  end

  factory :repository_git_option_key, class: 'RepositoryGitConfigKey::Option' do
    sequence(:key) { |n| "hookfoo.foo#{n}" }
    value { 'bar' }
    type { 'RepositoryGitConfigKey::Option' }
    association :repository, factory: :repository_gitolite
  end
end
