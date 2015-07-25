FactoryGirl.define do

  factory :repository_git_config_key_base, class: 'RepositoryGitConfigKey' do |f|
    f.sequence(:key) { |n| "hookfoo.foo#{n}" }
    f.value          'bar'
    f.association    :repository, factory: :repository_gitolite
  end

  factory :repository_git_config_key, class: 'RepositoryGitConfigKey::GitConfig' do |f|
    f.sequence(:key) { |n| "hookfoo.foo#{n}" }
    f.value          'bar'
    f.type           'RepositoryGitConfigKey::GitConfig'
    f.association    :repository, factory: :repository_gitolite
  end

  factory :repository_git_option_key, class: 'RepositoryGitConfigKey::Option' do |f|
    f.sequence(:key) { |n| "hookfoo.foo#{n}" }
    f.value          'bar'
    f.type           'RepositoryGitConfigKey::Option'
    f.association    :repository, factory: :repository_gitolite
  end

end
