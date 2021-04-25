# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    sequence(:lastname) { |n| "GroupTest#{n}" }
  end
end
