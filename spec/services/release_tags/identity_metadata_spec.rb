# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags::IdentityMetadata do
  let(:pid) { 'druid:bb004bn8654' }
  let(:collection_pid) { 'druid:xh235dd9059' }
  let(:apo_id) { 'druid:qv648vd4392' }
  let(:cocina_item) do
    Cocina::Models::DRO.new(externalIdentifier: pid,
                            type: Cocina::Models::Vocab.object,
                            label: 'Bryar 250 Trans-American: July 9-10',
                            version: 1,
                            identification: {},
                            access: {},
                            structural: { isMemberOf: [collection_pid] },
                            administrative: { hasAdminPolicy: apo_id,
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
                                              ] })
  end
  let(:releases) { described_class.for(cocina_item) }
  let(:bryar_trans_am_admin_tags) { AdministrativeTags.for(pid: pid) }
  let(:array_of_times) do
    ['2015-01-06 23:33:47Z', '2015-01-07 23:33:47Z', '2015-01-08 23:33:47Z', '2015-01-09 23:33:47Z'].map { |x| Time.parse(x).iso8601 }
  end

  before do
    # Create expected tags (see item fixture above) in the database
    create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Project : Revs'))
    create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'Remediated By : 3.25.0'))
    create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'tag : test1'))
    create(:administrative_tag, druid: pid, tag_label: create(:tag_label, tag: 'old : tag'))
  end

  describe 'Tag sorting, combining, and comparision functions' do
    let(:dummy_tags) do
      [
        { 'when' => array_of_times[0], 'tag' => "Project: Jim Harbaugh's Finest Moments At Stanford.", 'what' => 'self' },
        { 'when' => array_of_times[1], 'tag' => "Project: Jim Harbaugh's Even Finer Moments At Michigan.", 'what' => 'collection' }
      ]
    end

    describe '#newest_release_tag_in_an_array' do
      subject { releases.send(:newest_release_tag_in_an_array, dummy_tags) }

      it { is_expected.to eq dummy_tags[1] }
    end

    describe '#newest_release_tag' do
      subject { releases.newest_release_tag(dummy_hash) }

      let(:dummy_hash) { { 'Revs' => dummy_tags, 'FRDA' => dummy_tags } }

      it { is_expected.to eq('Revs' => dummy_tags[1], 'FRDA' => dummy_tags[1]) }
    end

    describe '#latest_applicable_release_tag_in_array' do
      it 'returns nil when no tags apply' do
        expect(releases.send(:latest_applicable_release_tag_in_array, dummy_tags, bryar_trans_am_admin_tags)).to be_nil
      end

      it 'returns a tag when it does apply' do
        valid_tag = { 'when' => array_of_times[3], 'tag' => 'Project : Revs' }
        expect(releases.send(:latest_applicable_release_tag_in_array, dummy_tags << valid_tag, bryar_trans_am_admin_tags)).to eq(valid_tag)
      end

      it 'returns a valid tag even if there are non applicable older ones in front of it' do
        valid_tag = { 'when' => array_of_times[2], 'tag' => 'Project : Revs' }
        newer_no_op_tag = { 'when' => array_of_times[3], 'tag' => "Jim Harbaugh's Nonexistent Moments With The Raiders" }
        expect(releases.send(:latest_applicable_release_tag_in_array, dummy_tags + [valid_tag, newer_no_op_tag], bryar_trans_am_admin_tags)).to eq(valid_tag)
      end

      it 'returns the most recent tag when there are two valid tags' do
        valid_tag = { 'when' => array_of_times[2], 'tag' => 'Project : Revs' }
        newer_valid_tag = { 'when' => array_of_times[3], 'tag' => 'tag : test1' }
        expect(releases.send(:latest_applicable_release_tag_in_array, dummy_tags + [valid_tag, newer_valid_tag], bryar_trans_am_admin_tags)).to eq(newer_valid_tag)
      end
    end

    describe '#does_release_tag_apply' do
      it 'recognizes a release tag with no tag attribute applies' do
        local_dummy_tag = { 'when' => array_of_times[0], 'who' => 'carrickr' }
        expect(releases.send(:does_release_tag_apply, local_dummy_tag, bryar_trans_am_admin_tags)).to be_truthy
      end

      it 'does not require admin tags to be passed in' do
        local_dummy_tag = { 'when' => array_of_times[0], 'who' => 'carrickr' }
        expect(releases.send(:does_release_tag_apply, local_dummy_tag)).to be_truthy
        expect(releases.send(:does_release_tag_apply, dummy_tags[0])).to be_falsey
      end
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

  describe '#release_tags' do
    subject(:release_tags) { releases.release_tags }

    context 'for an item that does not have any release tags' do
      let(:cocina_item) do
        Cocina::Models::DRO.new(externalIdentifier: pid,
                                type: Cocina::Models::Vocab.object,
                                label: 'Bryar 250 Trans-American: July 9-10',
                                version: 1,
                                identification: {},
                                access: {},
                                structural: {},
                                administrative: { hasAdminPolicy: apo_id,
                                                  releaseTags: [] })
      end

      it { is_expected.to eq({}) }
    end

    it 'returns the releases for an item that has release tags' do
      exp_result = {
        'Revs' => [
          { 'what' => 'collection', 'when' => Time.zone.parse('2015-01-06 23:33:47Z'), 'who' => 'carrickr', 'release' => true },
          { 'what' => 'self', 'when' => Time.zone.parse('2015-01-06 23:33:54Z'), 'who' => 'carrickr', 'release' => true },
          { 'what' => 'self', 'when' => Time.zone.parse('2015-01-06 23:40:01Z'), 'who' => 'carrickr', 'release' => false }
        ]
      }
      expect(release_tags).to eq exp_result
    end
  end

  describe '#release_tags_for_item_and_all_governing_sets' do
    let(:collection_object) do
      Cocina::Models::Collection.new(externalIdentifier: collection_pid,
                                     label: 'Some collection',
                                     version: 1,
                                     access: {},
                                     type: Cocina::Models::Vocab.collection)
    end
    let(:collection_release_tags) do
      {
        'Searchworks' => [
          { 'tag' => 'true', 'what' => 'collection', 'when' => Time.zone.parse('2015-01-06 23:33:47Z'), 'who' => 'carrickr', 'release' => true }
        ]
      }
    end
    let(:collection_tags) { instance_double(described_class, release_tags: collection_release_tags) }

    before do
      releases # call releases before subbing the invocation.
      allow(CocinaObjectStore).to receive(:find).with(collection_pid).and_return(collection_object)
      allow(described_class).to receive(:for).with(collection_object).and_return(collection_tags)
    end

    it 'gets tags from collections and the item' do
      # NOTE: Revs comes from the item, Searchworks comes from the collection
      expect(collection_release_tags.keys).not_to include('Revs')
      expect(releases.release_tags_for_item_and_all_governing_sets.keys).to include('Revs', 'Searchworks')
    end
  end
end
