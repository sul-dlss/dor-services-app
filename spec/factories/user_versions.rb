# frozen_string_literal: true

FactoryBot.define do
  factory :user_version do
    sequence(:version)
    withdrawn { false }
  end
end
