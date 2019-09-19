# frozen_string_literal: true

FactoryBot.define do
  factory :background_job_result do
    output { {} }
    status { 'pending' }
    code { 202 }
  end
end
