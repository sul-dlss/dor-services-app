# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::CompositeIndexer do
  let(:druid) { 'druid:mx123ms3333' }
  let(:apo_id) { 'druid:gf999hb9999' }
  let(:apo) { build(:admin_policy, id: apo_id, title: 'test admin policy') }
  let(:indexer) do
    described_class.new(
      Indexing::Indexers::DescriptiveMetadataIndexer,
      Indexing::Indexers::IdentifiableIndexer
    )
  end

  let(:cocina_item) do
    build(:dro, id: druid).new(
      description: {
        title: [{ value: 'Test item' }],
        subject: [{ type: 'topic', value: 'word' }],
        purl: 'https://purl.stanford.edu/mx123ms3333'
      }
    )
  end

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(apo)
  end

  describe 'to_solr' do
    let(:status) do
      instance_double(Dor::Services::Client::Status, milestones: {}, display: 'bad')
    end
    let(:doc) { indexer.new(id: druid, cocina: cocina_item).to_solr }

    it 'calls each of the provided indexers and combines the results' do
      expect(doc).to eq(
        'descriptive_tiv' => 'Test item word',
        'descriptive_teiv' => 'Test item word',
        'descriptive_text_nostem_i' => 'Test item word',
        'main_title_tenim' => ['Test item'],
        'full_title_tenim' => ['Test item'],
        'display_title_ss' => 'Test item',
        'nonhydrus_apo_title_ssim' => ['test admin policy'], # TODO: Remove
        'nonhydrus_apo_title_ssimdv' => ['test admin policy'],
        'apo_title_ssim' => ['test admin policy'],
        'metadata_source_ssim' => ['DOR'], # TODO: Remove
        'metadata_source_ssimdv' => ['DOR'],
        'druid_bare_ssi' => 'mx123ms3333',
        'druid_prefixed_ssi' => 'druid:mx123ms3333',
        'topic_ssim' => ['word'],
        'topic_tesim' => ['word']
      )
      # rubocop:enable Style/StringHashKeys
    end
  end
end
