# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicy do
  let(:minimal_cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: Cocina::Models::VERSION,
                                      externalIdentifier: 'druid:jt959wc5586',
                                      type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hy787xj5878',
                                        hasAgreement: 'druid:bb033gt0615',
                                        accessTemplate: { view: 'world', download: 'world' }
                                      }
                                    })
  end

  let(:cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: Cocina::Models::VERSION,
                                      externalIdentifier: 'druid:jt959wc5586',
                                      type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hy787xj5878',
                                        hasAgreement: 'druid:bb033gt0615',
                                        accessTemplate: { view: 'world', download: 'world' }
                                      },
                                      description: {
                                        title: [{ value: 'Test Admin Policy' }],
                                        purl: 'https://purl.stanford.edu/jt959wc5586'
                                      }
                                    })
  end

  describe 'to_cocina' do
    context 'with minimal admin_policy' do
      let(:admin_policy) { create(:ar_admin_policy) }

      it 'returns a Cocina::Model::AdminPolicy' do
        expect(admin_policy.to_cocina).to eq minimal_cocina_admin_policy
      end
    end

    context 'with complete AdminPolicy' do
      let(:admin_policy) { create(:ar_admin_policy, :with_admin_policy_description) }

      it 'returns a Cocina::Model::AdminPolicy' do
        expect(admin_policy.to_cocina).to eq cocina_admin_policy
      end
    end
  end

  describe 'presence validation' do
    subject(:apo) { described_class.create }

    it 'tells you if fields are missing' do
      expect(apo.errors.attribute_names).to match_array %i[external_identifier cocina_version
                                                           label version administrative]
    end
  end
end
