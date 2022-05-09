# frozen_string_literal: true

FactoryBot.define do
  factory :ar_admin_policy, class: 'AdminPolicy' do
    cocina_version { Cocina::Models::VERSION }
    external_identifier { 'druid:jt959wc5586' }
    label { 'Test Admin Policy' }
    version { 1 }
    transient do
      access_template { { view: 'world', download: 'world' } }
    end

    administrative do
      {
        hasAdminPolicy: 'druid:hy787xj5878',
        hasAgreement: 'druid:bb033gt0615',
        accessTemplate: access_template
      }
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
