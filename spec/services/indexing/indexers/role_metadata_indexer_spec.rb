# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::RoleMetadataIndexer do
  let(:apo_id) { 'druid:gf999hb9999' }
  let(:cocina) do
    build(:admin_policy, id: apo_id).new(
      administrative: {
        hasAdminPolicy: apo_id,
        hasAgreement: 'druid:bb033gt0615',
        roles: [
          { name: 'dor-apo-manager',
            members: [
              {
                type: 'workgroup',
                identifier: 'dlss:dor-admin'
              },
              {
                type: 'workgroup',
                identifier: 'sdr:developer'
              },
              {
                type: 'sunetid',
                identifier: 'tcramer'
              }
            ] }
        ],
        accessTemplate: { view: 'world', download: 'world' }
      }
    )
  end

  let(:indexer) do
    described_class.new(cocina:)
  end

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    it 'has the fields used by argo' do
      expect(doc['apo_register_permissions_ssim']).to eq ['workgroup:dlss:dor-admin', 'workgroup:sdr:developer', 'sunetid:tcramer']
      expect(doc['apo_role_dor-apo-manager_ssim']).to eq ['workgroup:dlss:dor-admin', 'workgroup:sdr:developer']
      expect(doc['apo_role_person_dor-apo-manager_ssim']).to eq ['sunetid:tcramer']
    end
  end
end
