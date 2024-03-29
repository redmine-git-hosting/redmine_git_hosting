# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:identifier) { |n| "project#{n}" }
    sequence(:name) { |n| "Project#{n}" }
  end
end
