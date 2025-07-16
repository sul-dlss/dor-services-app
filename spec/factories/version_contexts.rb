# frozen_string_literal: true

FactoryBot.define do
  factory :version_context do
    sequence :druid do |n|
      "druid:bb123bc#{format('%04d', n)}" # ensure we always have a valid druid format
    end
    version { 1 }
    values { { requireOCR: true, requireTranscript: true } }
  end
end
