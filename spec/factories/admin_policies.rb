# frozen_string_literal: true

FactoryBot.define do
  factory :admin_policy do
    cocina_version { '0.0.1' }
    external_identifier { 'druid:jt959wc5586' }
    label { 'Test Admin Policy' }
    version { 1 }
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878', hasAgreement: 'druid:bb033gt0615' }
    end
  end

  trait :with_admin_policy_description do
    description do
      {
        title: [{ value: 'Test Admin Policy' }],
        purl: 'https://purl.stanford.edu/jt959wc5586'
      }
    end
  end
end
