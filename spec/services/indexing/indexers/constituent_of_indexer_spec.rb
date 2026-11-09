# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::ConstituentOfIndexer do
  let(:indexer) { described_class.new(cocina: build(:dro), parent_virtual_objects:, administrative_tags: []) }

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }

    context 'when not a constituent of any virtual objects' do
      let(:parent_virtual_objects) { [] }

      it 'does not include the field' do
        expect(doc).not_to have_key('is_constituent_of_title_druid_ssimdv')
      end
    end

    context 'when a constituent of virtual objects' do
      let(:parent_virtual_objects) do
        [
          build(:dro, id: 'druid:bb777bb7777', title: 'Map set'),
          build(:dro, id: 'druid:dd666dd6666', title: 'Atlas: volumes')
        ]
      end

      it 'includes the composite virtual object title/druid values' do
        expect(doc['is_constituent_of_title_druid_ssimdv']).to eq(
          ['Map set:druid:bb777bb7777', 'Atlas: volumes:druid:dd666dd6666']
        )
      end
    end

    context 'when a virtual object has no title' do
      let(:virtual_object) { build(:dro, id: 'druid:bb777bb7777') }
      let(:parent_virtual_objects) { [virtual_object] }

      before do
        allow(Cocina::Models::Builders::TitleBuilder).to receive(:build).and_return('')
      end

      it 'does not include the virtual object' do
        expect(doc).not_to have_key('is_constituent_of_title_druid_ssimdv')
      end
    end
  end
end
