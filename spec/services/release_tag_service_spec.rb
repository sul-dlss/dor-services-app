# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTagService do
  let(:druid) { 'druid:bb004bn8654' }

  describe '.create' do
    subject(:create_tag) { described_class.create(cocina_object:, tag:) }

    let(:tag) { Dor::ReleaseTag.new(to: 'Earthworks', what: 'self', who: 'cathy', date: 2.days.ago.iso8601) }
    let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, externalIdentifier: druid, version: 2) }

    before do
      allow(Indexer).to receive(:reindex)
      allow(Workflow::Service).to receive(:create)
    end

    it 'adds another release tag' do
      expect { create_tag }.to change { ReleaseTag.where(druid:).count }.by(1)
      expect(Indexer).to have_received(:reindex).with(cocina_object:)
      expect(Workflow::Service).to have_received(:create).with(workflow_name: 'releaseWF',
                                                               druid:, version: 2)
    end

    context 'when create_only is true' do
      subject(:create_tag) { described_class.create(cocina_object:, tag:, create_only: true) }

      it 'adds another release tag without reindexing or starting workflow' do
        expect { create_tag }.to change { ReleaseTag.where(druid:).count }.by(1)
        expect(Indexer).not_to have_received(:reindex)
        expect(Workflow::Service).not_to have_received(:create)
      end
    end
  end

  describe '.tags' do
    subject(:releases) { described_class.tags(druid:) }

    let!(:release_tag) { create(:release_tag, druid:) }

    it 'returns release tags from the ReleaseTag objects' do
      expect(releases).to eq [
        release_tag.to_cocina
      ]
    end
  end

  describe '.latest_release_tags' do
    subject(:latest_tags) { described_class.latest_release_tags(druid:) }

    let!(:latest_sw_release_tag) { create(:release_tag, druid:, released_to: 'Searchworks', created_at: 1.day.ago) }
    let!(:latest_ew_release_tag) { create(:release_tag, druid:, released_to: 'Earthworks', created_at: 1.day.ago) }

    before do
      create(:release_tag, druid:, released_to: 'Searchworks', created_at: 2.days.ago)
      create(:release_tag, druid:, released_to: 'Earthworks', created_at: 2.days.ago)
    end

    it 'returns the latest released tag for each destination' do
      expect(latest_tags).to contain_exactly(latest_sw_release_tag.to_cocina, latest_ew_release_tag.to_cocina)
    end
  end
end
