# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::IdentifiableIndexer do
  let(:druid) { 'druid:rt923jk3422' }
  let(:apo_id) { 'druid:bd999bd9999' }
  let(:agreement_id) { 'druid:bb033gt0615' }
  let(:cocina_item) do
    build(:dro, id: druid, admin_policy_id: apo_id).new(
      identification:
    )
  end
  let(:identification) do
    {
      catalogLinks: [
        { catalog: 'symphony', catalogRecordId: '1234', refresh: true },
        { catalog: 'previous symphony', catalogRecordId: '12345', refresh: false },
        { catalog: 'folio', catalogRecordId: 'a1234', refresh: true },
        { catalog: 'previous folio', catalogRecordId: 'a12345', refresh: false },
        { catalog: 'previous folio', catalogRecordId: 'a123456', refresh: false }
      ],
      sourceId: 'sul:1234'
    }
  end
  let(:administrative_tags_finder) { ->(_druid) { [] } }
  let(:indexer) do
    described_class.new(cocina: cocina_item)
  end

  before do
    described_class.reset_cache!
  end

  describe '#identity_metadata_sources' do
    it 'indexes metadata sources' do
      expect(indexer.send(:identity_metadata_sources)).to eq %w[Folio]
    end
  end

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }
    let(:mock_rel_druid) { 'druid:qf999gg9999' }
    let(:related) { build(:admin_policy, id: apo_id) }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(related)
    end

    it 'does not index agreement fields for a non-APO' do
      expect(doc).not_to include('agreement_ssi', 'agreement_ssidv')
    end

    context 'when APO is not found' do
      before do
        allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      end

      it 'generates apo title fields' do
        expect(doc['apo_title_ssimdv'].first).to eq apo_id
      end
    end

    context 'when APO is found' do
      let(:related) { build(:collection, id: mock_rel_druid, admin_policy_id: apo_id, title: 'collection title') }

      it 'generates apo title fields' do
        expect(doc['apo_title_ssimdv'].first).to eq 'collection title'
      end

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssimdv' => %w[Folio])
      end
    end

    context 'when the object is an APO' do
      let(:cocina_item) { build(:admin_policy, id: druid, admin_policy_id: apo_id, agreement_id:) }
      let(:agreement) do
        build(:dro, id: agreement_id, type: Cocina::Models::ObjectType.agreement, title: 'Agreement title')
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with(apo_id).and_return(related)
        allow(CocinaObjectStore).to receive(:find).with(agreement_id).and_return(agreement)
      end

      it 'indexes the agreement druid and title as single values' do
        expect(doc).to include(
          'agreement_ssi' => agreement_id,
          'agreement_ssidv' => 'Agreement title'
        )
      end

      context 'when the agreement is not found' do
        before do
          allow(CocinaObjectStore).to receive(:find).with(agreement_id).and_raise(
            CocinaObjectStore::CocinaObjectNotFoundError
          )
        end

        it 'uses the agreement druid as the title' do
          expect(doc).to include(
            'agreement_ssi' => agreement_id,
            'agreement_ssidv' => agreement_id
          )
        end
      end
    end

    context 'without catalogLinks' do
      let(:identification) { { sourceId: 'sul:1234' } }

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssimdv' => ['DOR'])
      end
    end

    context 'with only previous-type catalogLinks' do
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'previous symphony', catalogRecordId: '12345', refresh: false },
            { catalog: 'previous folio', catalogRecordId: 'a12345', refresh: false },
            { catalog: 'previous folio', catalogRecordId: 'a123456', refresh: false }
          ],
          sourceId: 'sul:1234'
        }
      end

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssimdv' => ['DOR'])
      end
    end

    context 'with no identification sub-schema' do
      let(:cocina_item) { build(:dro, id: druid, admin_policy_id: apo_id) }

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssimdv' => ['DOR'])
      end
    end
  end
end
