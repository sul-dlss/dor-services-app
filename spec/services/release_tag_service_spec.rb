# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTagService do
  let(:releases) { described_class.new(cocina_object) }
  let(:cocina_object) do
    build(:dro, id: druid, collection_ids:).new(
      administrative: {
        hasAdminPolicy: apo_id,
        releaseTags: cocina_release_tags
      }
    )
  end
  let(:apo_id) { 'druid:qv648vd4392' }
  let(:collection_druid) { 'druid:xh235dd9059' }
  let(:druid) { 'druid:bb004bn8654' }
  let(:cocina_release_tags) { [] }
  let(:collection_ids) { [] }

  describe '.for_public_metadata' do
    subject(:releases) { described_class.for_public_metadata(cocina_object:) }

    context 'when item has self tags' do
      let!(:searchworks_self_release_tag) { create(:release_tag, druid:, released_to: 'Searchworks', what: 'self') }
      let!(:earthworks_self_release_tag) { create(:release_tag, druid:, released_to: 'Earthworks', what: 'self') }

      it 'returns the list of release tags' do
        expect(releases).to eq [
          searchworks_self_release_tag.to_cocina,
          earthworks_self_release_tag.to_cocina
        ]
      end
    end

    context 'when item has multiple self tags' do
      let!(:self_release_tag) { create(:release_tag, druid:, released_to: 'Searchworks', what: 'self') }

      before do
        create(:release_tag, druid:, released_to: 'Searchworks', what: 'self', created_at: 1.day.ago)
      end

      it 'returns the most recent tag' do
        expect(releases).to eq [
          self_release_tag.to_cocina
        ]
      end
    end

    context 'when a collection has a self tag' do
      let(:collection_ids) { [collection_druid] }

      before do
        create(:release_tag, druid: collection_druid, released_to: 'Searchworks', what: 'self')
      end

      it 'ignores the collection self tag' do
        expect(releases).to eq []
      end
    end

    context 'when a collection has a collection tag' do
      let(:collection_ids) { [collection_druid] }

      let!(:collection_release_tag) { create(:release_tag, druid: collection_druid, released_to: 'Searchworks', what: 'collection') }

      it 'returns the collection tag' do
        expect(releases).to eq [collection_release_tag.to_cocina]
      end
    end

    context 'when a collection has a collection tag (created first) and the item has a self tag' do
      let(:collection_ids) { [collection_druid] }

      let!(:self_release_tag) { create(:release_tag, druid:, released_to: 'Searchworks', what: 'self') }

      before do
        create(:release_tag, druid: collection_druid, released_to: 'Searchworks', what: 'collection', created_at: 1.day.ago)
      end

      it 'prioritizes the item self tag' do
        expect(releases).to eq [self_release_tag.to_cocina]
      end
    end

    context 'when a collection has a collection tag and the item has a self tag (created first)' do
      let(:collection_ids) { [collection_druid] }

      let!(:self_release_tag) { create(:release_tag, druid:, released_to: 'Searchworks', what: 'self', created_at: 1.day.ago) }

      before do
        create(:release_tag, druid: collection_druid, released_to: 'Searchworks', what: 'collection')
      end

      it 'prioritizes the item self tag' do
        expect(releases).to eq [self_release_tag.to_cocina]
      end
    end
  end

  describe '.released_to_searchworks?' do
    subject { described_class.released_to_searchworks?(cocina_object:) }

    context 'when release_data tag has release to=Searchworks and value is true' do
      before do
        create(:release_tag, druid:, released_to: 'Searchworks', release: true)
      end
      # let(:release_data) { [{ to: 'Searchworks', release: true }] }

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=searchworks (all lowercase) and value is true' do
      before do
        create(:release_tag, druid:, released_to: 'searchworks', release: true)
      end

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=SearchWorks (camelcase) and value is true' do
      before do
        create(:release_tag, druid:, released_to: 'SearchWorks', release: true)
      end

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=Searchworks and value is false' do
      before do
        create(:release_tag, druid:, released_to: 'Searchworks', release: false)
      end

      it { is_expected.to be false }
    end

    context 'when there are no release tags at all' do
      it { is_expected.to be false }
    end

    context 'when there are non searchworks related release tags' do
      before do
        create(:release_tag, druid:, released_to: 'Revs', release: true)
      end

      it { is_expected.to be false }
    end
  end

  describe '.create' do
    subject(:create_tag) { described_class.create(cocina_object:, tag:) }

    let(:tag) { Cocina::Models::ReleaseTag.new(to: 'Earthworks', what: 'self', who: 'cathy', date: 2.days.ago.iso8601) }

    let(:cocina_release_tags) do
      [
        {
          who: 'carrickr',
          what: 'collection',
          date: '2015-01-06T23:33:47.000+00:00',
          to: 'Revs',
          release: true
        },
        {
          who: 'carrickr',
          what: 'self',
          date: '2015-01-06T23:33:54.000+00:00',
          to: 'Revs',
          release: true
        },
        {
          who: 'carrickr',
          what: 'self',
          date: '2015-01-06T23:40:01.000+00:00',
          to: 'Revs',
          release: false
        }
      ]
    end

    before do
      allow(CocinaObjectStore).to receive(:store)
    end

    context 'when ReleaseTag objects already exist for this item' do
      before do
        create(:release_tag, druid:)
      end

      it 'adds another release tag and records to the cocina' do
        expect { create_tag }.to change { ReleaseTag.where(druid:).count }.by(1)
        expect(CocinaObjectStore).to have_received(:store) do |dro|
          expect(dro.administrative.releaseTags.size).to eq 4
        end
      end
    end

    context 'when no ReleaseTag objects exist for this item' do
      it 'records to the cocina and adds no ReleaseTag' do
        expect { create_tag }.not_to(change { ReleaseTag.where(druid:).count })
        expect(CocinaObjectStore).to have_received(:store) do |dro|
          expect(dro.administrative.releaseTags.size).to eq 4
        end
      end
    end
  end

  describe '.item_tags' do
    subject(:releases) { described_class.item_tags(cocina_object:) }

    context 'when ReleaseTag objects exist for this item' do
      let!(:release_tag) { create(:release_tag) }

      it 'returns release tags from the ReleaseTag objects' do
        expect(releases).to eq [
          release_tag.to_cocina
        ]
      end
    end

    context 'when no ReleaseTag objects exist for this item' do
      let(:cocina_release_tags) do
        [
          {
            who: 'carrickr',
            what: 'collection',
            date: '2015-01-06T23:33:47.000+00:00',
            to: 'Revs',
            release: true
          }
        ]
      end

      it 'returns release tags from the cocina object' do
        expect(releases).to eq [
          Cocina::Models::ReleaseTag.new(to: 'Revs', release: true, date: '2015-01-06T23:33:47Z', who: 'carrickr', what: 'collection')
        ]
      end
    end
  end
end