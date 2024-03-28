# frozen_string_literal: true

FactoryBot.define do
  factory :repository_object do
    type { '' }
    external_identifier { 'MyString' }
    lock { 'MyString' }
  end
end
