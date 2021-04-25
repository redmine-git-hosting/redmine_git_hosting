# frozen_string_literal: true

FactoryBot.define do
  factory :repository_svn, class: 'Repository::Subversion' do
    is_default { false }
  end
end
