# frozen_string_literal: true

FactoryBot.define do
  factory :release_tag do
    druid { 'MyString' }
    who { 'MyString' }
    what { 'MyString' }
    released_to { 'MyString' }
    release { false }
  end
end
