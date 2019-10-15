# frozen_string_literal: true

FactoryBot.define do
  factory :background_job_result do
    output { {} }
    status { 'pending' }
  end
end
