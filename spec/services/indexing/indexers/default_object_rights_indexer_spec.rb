# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DefaultObjectRightsIndexer do
  let(:cocina_apo) do
    build(:admin_policy, id: 'druid:bb123cd4567').new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:bb033gt0615',
        accessTemplate: {
          useAndReproductionStatement: 'Rights are owned by Stanford University Libraries.',
          copyright: 'Additional copyright info',
          view: 'location-based',
          download: 'location-based',
          location: 'spec'
        }
      }
    )
  end

  describe '#to_solr' do
    let(:indexer) do
      Indexing::Indexers::CompositeIndexer.new(
        described_class
      ).new(id: 'druid:bb123cd4567', cocina: cocina_apo)
    end
    let(:doc) { indexer.to_solr }

    it 'makes a solr doc' do
      expect(doc).to match a_hash_including('use_statement_ssim' =>
        'Rights are owned by Stanford University Libraries.')
      expect(doc).to match a_hash_including('copyright_ssim' => 'Additional copyright info')
      expect(doc).to match a_hash_including('rights_descriptions_ssimdv' => 'dark')
      expect(doc).to match a_hash_including('default_rights_descriptions_ssim' => ['location: spec'])
      # rubocop:enable Style/StringHashKeys
    end
  end
end
