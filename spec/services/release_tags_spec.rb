# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  let(:releases) { described_class.new(cocina_object) }
  let(:cocina_object) do
    build(:dro, id: druid, collection_ids: [collection_druid]).new(
      administrative: {
        hasAdminPolicy: apo_id,
        releaseTags: [
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
      }
    )
  end
  let(:apo_id) { 'druid:qv648vd4392' }
  let(:collection_druid) { 'druid:xh235dd9059' }
  let(:druid) { 'druid:bb004bn8654' }

  describe '.for_public_metadata' do
    subject(:releases) { described_class.for_public_metadata(cocina_object:) }

    context 'when item has a self tag' do
      let(:cocina_object) do
        build(:dro).new(
          administrative: {
            hasAdminPolicy: 'druid:fg890hx1234',
            releaseTags: [
              {
                who: 'dhartwig',
                what: 'collection',
                date: '2019-01-18T17:03:35.000+00:00',
                to: 'Searchworks',
                release: true
              }
            ]
          }
        )
      end

      it 'returns the list of release tags' do
        expect(releases).to eq [
          Cocina::Models::ReleaseTag.new(to: 'Searchworks', release: true, date: '2019-01-18T17:03:35Z', who: 'dhartwig', what: 'collection')
        ]
      end
    end

    context 'when collection has a self tag' do
      let(:collection_druid) { 'druid:xh235dd9059' }

      let(:cocina_object) do
        build(:dro).new(structural: {
                          isMemberOf: [collection_druid]
                        })
      end

      let(:collection_object) do
        build(:collection, id: collection_druid).new(administrative: {
                                                       hasAdminPolicy: apo_id,
                                                       releaseTags: [
                                                         {
                                                           who: 'dhartwig',
                                                           what: 'self',
                                                           date: '2019-01-18T17:03:35.000+00:00',
                                                           to: 'Searchworks',
                                                           release: true
                                                         }
                                                       ]
                                                     })
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection_object)
      end

      it { is_expected.to be_empty }
    end

    context 'when collection has a collection tag and the item has a self tag' do
      let(:collection_druid) { 'druid:xh235dd9059' }

      let(:cocina_object) do
        build(:dro).new(structural: {
                          isMemberOf: [collection_druid]
                        },
                        administrative: {
                          hasAdminPolicy: apo_id,
                          releaseTags: [
                            {
                              who: 'dhartwig',
                              what: 'self',
                              date: '2019-01-18T17:03:35.000+00:00',
                              to: 'Earthworks',
                              release: true
                            }
                          ]
                        })
      end

      let(:collection_object) do
        build(:collection, id: collection_druid).new(administrative: {
                                                       hasAdminPolicy: apo_id,
                                                       releaseTags: [
                                                         {
                                                           who: 'dhartwig',
                                                           what: 'collection',
                                                           date: '2019-01-18T17:03:35.000+00:00',
                                                           to: 'Searchworks',
                                                           release: true
                                                         }
                                                       ]
                                                     })
      end

      before do
        allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection_object)
      end

      it 'returns the tags from collections and the item' do
        expect(releases).to eq [
          Cocina::Models::ReleaseTag.new(to: 'Earthworks', release: true, date: '2019-01-18T17:03:35Z', who: 'dhartwig', what: 'self'),
          Cocina::Models::ReleaseTag.new(to: 'Searchworks', release: true, date: '2019-01-18T17:03:35Z', who: 'dhartwig', what: 'collection')
        ]
      end
    end
  end

  describe '.released_to_searchworks?' do
    subject { described_class.released_to_searchworks?(cocina_object:) }

    let(:cocina_object) do
      build(:dro).new(
        administrative: {
          hasAdminPolicy: apo_id,
          releaseTags: release_data
        }
      )
    end

    context 'when release_data tag has release to=Searchworks and value is true' do
      let(:release_data) { [{ to: 'Searchworks', release: true }] }

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=searchworks (all lowercase) and value is true' do
      let(:release_data) { [{ to: 'searchworks', release: true }] }

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=SearchWorks (camcelcase) and value is true' do
      let(:release_data) { [{ to: 'SearchWorks', release: true }] }

      it { is_expected.to be true }
    end

    context 'when release_data tag has release to=Searchworks and value is false' do
      let(:release_data) { [{ to: 'Searchworks', release: false }] }

      it { is_expected.to be false }
    end

    context 'when release_data tag has release to=Searchworks but no specified release value' do
      let(:release_data) { [{ to: 'Searchworks' }] }

      it { is_expected.to be false }
    end

    context 'when there are no release tags at all' do
      let(:release_data) { [] }

      it { is_expected.to be false }
    end

    context 'when there are non searchworks related release tags' do
      let(:release_data) { [{ to: 'Revs', release: true }] }

      it { is_expected.to be false }
    end
  end

  describe '.create' do
    subject(:create_tag) { described_class.create(cocina_object:, tag:) }

    let(:tag) { Cocina::Models::ReleaseTag.new(to: 'Earthworks', what: 'self', who: 'cathy', date: 2.days.ago.iso8601) }

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
      it 'returns release tags from the cocina object' do
        expect(releases).to eq [
          Cocina::Models::ReleaseTag.new(to: 'Revs', release: true, date: '2015-01-06T23:33:47Z', who: 'carrickr', what: 'collection'),
          Cocina::Models::ReleaseTag.new(to: 'Revs', release: true, date: '2015-01-06T23:33:54Z', who: 'carrickr', what: 'self'),
          Cocina::Models::ReleaseTag.new(to: 'Revs', release: false, date: '2015-01-06T23:40:01Z', who: 'carrickr', what: 'self')
        ]
      end
    end
  end
end
