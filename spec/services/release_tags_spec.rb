# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  let(:bryar_trans_am_admin_tags) { AdministrativeTags.for(identifier: druid) }
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

  before do
    # Create expected tags (see item fixture above) in the database
    create(:administrative_tag, druid:, tag_label: create(:tag_label, tag: 'Project : Revs'))
    create(:administrative_tag, druid:, tag_label: create(:tag_label, tag: 'Remediated By : 3.25.0'))
    create(:administrative_tag, druid:, tag_label: create(:tag_label, tag: 'tag : test1'))
    create(:administrative_tag, druid:, tag_label: create(:tag_label, tag: 'old : tag'))
  end

  describe '.for' do
    subject(:releases) { described_class.for(cocina_object:) }

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

      it 'returns the hash of release tags' do
        expect(releases).to eq(
          'Searchworks' => {
            'release' => true
          }
        )
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

      it 'gets tags from collections and the item' do
        expect(releases).to eq('Earthworks' => { 'release' => true }, 'Searchworks' => { 'release' => true })
      end
    end
  end

  describe 'Tag sorting, combining, and comparision functions' do
    let(:dummy_tags) do
      [
        Cocina::Models::ReleaseTag.new(date: '2015-01-06 23:33:47Z', 'what' => 'self'),
        Cocina::Models::ReleaseTag.new(date: '2015-01-07 23:33:47Z', 'what' => 'collection')
      ]
    end

    describe '#newest_release_tag_in_an_array' do
      subject { releases.send(:newest_release_tag_in_an_array, dummy_tags) }

      it { is_expected.to eq dummy_tags[1] }
    end

    describe '#newest_release_tag' do
      subject { releases.send(:newest_release_tag, dummy_hash) }

      let(:dummy_hash) { { 'Revs' => dummy_tags, 'FRDA' => dummy_tags } }

      it { is_expected.to eq('Revs' => dummy_tags[1], 'FRDA' => dummy_tags[1]) }
    end

    describe '#tags_for_what_value' do
      it 'only returns tags for the specific what value' do
        expect(releases.send(:tags_for_what_value, { 'Revs' => dummy_tags }, 'self')).to eq('Revs' => [dummy_tags[0]])
        expect(releases.send(:tags_for_what_value, { 'Revs' => dummy_tags, 'FRDA' => dummy_tags }, 'collection')).to eq('Revs' => [dummy_tags[1]], 'FRDA' => [dummy_tags[1]])
      end
    end

    describe '#combine_two_release_tag_hashes' do
      it 'combines two hashes of tags without overwriting any data' do
        h_one = { 'Revs' => [dummy_tags[0]] }
        h_two = { 'Revs' => [dummy_tags[1]], 'FRDA' => dummy_tags }
        expected_result = { 'Revs' => dummy_tags, 'FRDA' => dummy_tags }
        expect(releases.send(:combine_two_release_tag_hashes, h_one, h_two)).to eq(expected_result)
      end
    end

    it 'only returns self release tags' do
      expect(releases.send(:self_release_tags, 'Revs' => dummy_tags, 'FRDA' => dummy_tags, 'BV' => [dummy_tags[1]])).to eq('Revs' => [dummy_tags[0]], 'FRDA' => [dummy_tags[0]])
    end
  end

  describe '#release_tags_by_project' do
    subject(:release_tags) { releases.release_tags_by_project }

    context 'when an item does not have any release tags' do
      let(:cocina_object) do
        build(:dro, id: druid).new(
          administrative: {
            hasAdminPolicy: apo_id,
            releaseTags: []
          }
        )
      end

      it { is_expected.to eq({}) }
    end

    it 'returns the releases for an item that has release tags' do
      exp_result = {
        'Revs' => [
          Cocina::Models::ReleaseTag.new(to: 'Revs', 'what' => 'collection', date: '2015-01-06 23:33:47Z', 'who' => 'carrickr', 'release' => true),
          Cocina::Models::ReleaseTag.new(to: 'Revs', 'what' => 'self', date: '2015-01-06 23:33:54Z', 'who' => 'carrickr', 'release' => true),
          Cocina::Models::ReleaseTag.new(to: 'Revs', 'what' => 'self', date: '2015-01-06 23:40:01Z', 'who' => 'carrickr', 'release' => false)
        ]
      }
      expect(release_tags).to eq exp_result
    end
  end
end
