# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    druid { 'druid:xz456jk0987' }
    event_type { 'important_action_completed' }
    data { { other: 'useful info specific to the event/occurrence' } }
  end
end
