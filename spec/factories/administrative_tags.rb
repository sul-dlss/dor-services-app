# frozen_string_literal: true

FactoryBot.define do
  factory :administrative_tag do
    druid { 'druid:xz456jk0987' }
    tag { 'My : Object : Rules' }
  end
end
