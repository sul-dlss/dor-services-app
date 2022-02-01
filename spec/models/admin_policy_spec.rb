# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPolicy do
  let(:minimal_cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: '0.0.1',
                                      externalIdentifier: 'druid:jt959wc5586',
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: { hasAdminPolicy: 'druid:hy787xj5878', hasAgreement: 'druid:bb033gt0615' }
                                    })
  end

  let(:cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: '0.0.1',
                                      externalIdentifier: 'druid:jt959wc5586',
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: { hasAdminPolicy: 'druid:hy787xj5878', hasAgreement: 'druid:bb033gt0615' },
                                      description: {
                                        title: [{ value: 'Test Admin Policy' }],
                                        purl: 'https://purl.stanford.edu/jt959wc5586'
                                      }
                                    })
  end

  describe 'to_cocina' do
    context 'with minimal admin_policy' do
      let(:admin_policy) { create(:admin_policy) }

      it 'returns a Cocina::Model::AdminPolicy' do
        expect(admin_policy.to_cocina).to eq(minimal_cocina_admin_policy)
      end
    end

    context 'with complete AdminPolicy' do
      let(:admin_policy) { create(:admin_policy, :with_admin_policy_description) }

      it 'returns a Cocina::Model::AdminPolicy' do
        expect(admin_policy.to_cocina).to eq(cocina_admin_policy)
      end
    end
  end

  describe 'from_cocina' do
    context 'with a minimal AdminPolicy' do
      let(:admin_policy) { described_class.from_cocina(minimal_cocina_admin_policy) }

      it 'returns a AdminPolicy' do
        expect(admin_policy).to be_a(described_class)
        expect(admin_policy.external_identifier).to eq(minimal_cocina_admin_policy.externalIdentifier)
        expect(admin_policy.cocina_version).to eq(minimal_cocina_admin_policy.cocinaVersion)
        expect(admin_policy.label).to eq(minimal_cocina_admin_policy.label)
        expect(admin_policy.version).to eq(minimal_cocina_admin_policy.version)
        expect(admin_policy.administrative).to eq(cocina_admin_policy.administrative.to_h.with_indifferent_access)
        expect(admin_policy.description).to be_nil
      end
    end

    context 'with a complete AdminPolicy' do
      let(:admin_policy) { described_class.from_cocina(cocina_admin_policy) }

      it 'returns a AdminPolicy' do
        expect(admin_policy).to be_a(described_class)
        expect(admin_policy.external_identifier).to eq(cocina_admin_policy.externalIdentifier)
        expect(admin_policy.cocina_version).to eq(cocina_admin_policy.cocinaVersion)
        expect(admin_policy.label).to eq(cocina_admin_policy.label)
        expect(admin_policy.version).to eq(cocina_admin_policy.version)
        expect(admin_policy.administrative).to eq(cocina_admin_policy.administrative.to_h.with_indifferent_access)
        expect(admin_policy.description).to eq(cocina_admin_policy.description.to_h.with_indifferent_access)
      end
    end
  end
end
