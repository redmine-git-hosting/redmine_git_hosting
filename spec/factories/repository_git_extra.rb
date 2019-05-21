FactoryBot.define do
  factory :repository_git_extra do
    git_http { 0 }
    default_branch { 'master' }
    association :repository, factory: :repository_gitolite
    key { RedmineGitHosting::Utils::Crypto.generate_secret(64) }
  end
end
