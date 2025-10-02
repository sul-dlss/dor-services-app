# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::IdentityMetadataIndexer do
  let(:druid) { 'druid:rt923jk3421' }
  let(:cocina_object) { build(:dro_with_metadata, type:, id: druid).new(identification:) }
  let(:indexer) { described_class.new(cocina: cocina_object) }

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    context 'with an item' do
      let(:type) { Cocina::Models::ObjectType.book }
      let(:identification) do
        {
          sourceId: 'google:STANFORD_342837261527',
          catalogLinks: [
            {
              catalog: 'symphony',
              catalogRecordId: '129483625',
              refresh: true
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '666',
              refresh: true
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '999',
              refresh: true
            },
            {
              catalog: 'folio',
              catalogRecordId: 'a129483625',
              refresh: true
            },
            {
              catalog: 'previous folio',
              catalogRecordId: 'a777',
              refresh: true
            }
          ],
          barcode: '36105049267078',
          doi: '10.25740/yr775yn6440'
        }
      end

      it 'has the fields used by argo' do
        expect(doc).to include(
          'barcode_id_ssim' => ['36105049267078'], # TODO: Remove
          'barcode_id_ssimdv' => ['36105049267078'],
          'folio_instance_hrid_ssim' => ['a129483625'],
          'identifier_ssim' => ['google:STANFORD_342837261527', 'barcode:36105049267078',
                                'folio:a129483625'],
          'identifier_tesim' => ['google:STANFORD_342837261527', 'barcode:36105049267078',
                                 'folio:a129483625'],
          'objectType_ssim' => ['item'],
          'source_id_ssi' => 'google:STANFORD_342837261527',
          'doi_ssim' => ['10.25740/yr775yn6440']
        )
      end
      # rubocop:enable Style/StringHashKeys
    end

    context 'with an agreement' do
      let(:type) { Cocina::Models::ObjectType.agreement }
      let(:identification) { { sourceId: 'sul:1234' } }

      # rubocop:disable Style/StringHashKeys
      it 'has the fields used by argo' do
        expect(doc).to include(
          'barcode_id_ssim' => [], # TODO: Remove
          'barcode_id_ssimdv' => [],
          'identifier_ssim' => ['sul:1234'],
          'identifier_tesim' => ['sul:1234'],
          'objectType_ssim' => ['agreement'],
          'source_id_ssi' => 'sul:1234',
          'source_id_text_nostem_i' => 'sul:1234'
        )
      end
      # rubocop:enable Style/StringHashKeys
    end

    context 'with a collection' do
      # Collection objects have no structural attribute
      let(:cocina_object) { build(:collection_with_metadata, id: druid).new(identification:) }
      let(:identification) do
        {
          sourceId: 'google:STANFORD_342837261527',
          catalogLinks: [
            {
              catalog: 'symphony',
              catalogRecordId: '129483625',
              refresh: true
            },
            {
              catalog: 'folio',
              catalogRecordId: 'a129483625',
              refresh: true
            }
          ]
        }
      end

      # rubocop:disable Style/StringHashKeys
      it 'has the fields used by argo' do
        expect(doc).to include(
          'barcode_id_ssim' => [], # TODO: Remove
          'barcode_id_ssimdv' => [],
          'folio_instance_hrid_ssim' => ['a129483625'],
          'identifier_ssim' => ['google:STANFORD_342837261527', 'folio:a129483625'],
          'identifier_tesim' => ['google:STANFORD_342837261527', 'folio:a129483625'],
          'objectType_ssim' => ['collection'],
          'source_id_ssi' => 'google:STANFORD_342837261527',
          'source_id_text_nostem_i' => 'google:STANFORD_342837261527'
        )
      end
      # rubocop:enable Style/StringHashKeys
    end
  end
end
