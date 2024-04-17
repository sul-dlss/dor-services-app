# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexer do
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#reindex' do
    before do
      allow(DorIndexing).to receive(:build)
    end

    it 'reindexes the object' do
      described_class.reindex(cocina_object:)
      expect(DorIndexing).to have_received(:build).with(
        cocina_with_metadata: cocina_object,
        workflow_client: Dor::Workflow::Client,
        cocina_finder: Proc,
        administrative_tags_finder: Proc,
        release_tags_finder: Proc
      )
    end
  end

  describe '#cocina_finder' do
    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    end

    it 'finds the object' do
      expect(described_class.cocina_finder.call(druid)).to eq(cocina_object)
      expect(CocinaObjectStore).to have_received(:find).with(druid)
    end
  end

  describe '#administrative_tags_finder' do
    let(:tag) { instance_double(AdministrativeTag) }

    before do
      allow(AdministrativeTags).to receive(:for).and_return([tag])
    end

    it 'finds the tags' do
      expect(described_class.administrative_tags_finder.call(druid)).to eq([tag])
      expect(AdministrativeTags).to have_received(:for).with(identifier: druid)
    end
  end

  describe '#release_tags_finder' do
    let(:tag) { instance_double(ReleaseTag) }

    before do
      allow(ReleaseTagService).to receive(:item_tags).and_return([tag])
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    end

    it 'finds the tags' do
      expect(described_class.release_tags_finder.call(druid)).to eq([tag])
      expect(ReleaseTagService).to have_received(:item_tags).with(cocina_object:)
    end
  end
end
