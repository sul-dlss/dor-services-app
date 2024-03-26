# frozen_string_literal: true

FactoryBot.define do
  factory :release_tag do
    druid { 'druid:bb004bn8654' }
    who { 'Bob' }
    what { 'self' }
    released_to { 'Searchworks' }
    release { false }
  end
end
