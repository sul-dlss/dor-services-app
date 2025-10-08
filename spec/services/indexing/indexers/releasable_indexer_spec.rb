# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::ReleasableIndexer do
  let(:cocina) { build(:dro).new(structural: { isMemberOf: collection_druids }) }
  let(:collection_druids) { [] }
  let(:release_tags) { [] }

  describe 'to_solr' do
    let(:doc) do
      described_class.new(cocina:, release_tags:, parent_collections_release_tags:).to_solr
    end

    let(:parent_collections_release_tags) { {} }

    context 'with no parent collection' do
      context 'when multiple releaseTags are present for the same destination' do
        let(:release_tags) do
          [
            Dor::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Dor::ReleaseTag.new(to: 'Project', release: false, date: '2016-12-21T17:31:18.000+00:00', what: 'self'),
            Dor::ReleaseTag.new(to: 'Project', release: true, date: '2021-05-12T21:05:21.000+00:00', what: 'self'),
            Dor::ReleaseTag.new(to: 'test_target', release: true, what: 'self'),
            Dor::ReleaseTag.new(to: 'test_nontarget', release: false, date: '2016-12-16T22:52:35.000+00:00',
                                what: 'self'),
            Dor::ReleaseTag.new(to: 'test_nontarget', release: true, date: '2016-11-16T22:52:35.000+00:00',
                                what: 'self')
          ]
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[Project test_target])
        end
      end

      context 'when Searchworks, Earthworks, and PURL sitemap tags are present' do
        let(:release_tags) do
          [
            Dor::ReleaseTag.new(to: 'Searchworks', release: true, date: '2021-05-12T21:05:21.000+00:00',
                                what: 'self'),
            Dor::ReleaseTag.new(to: 'Earthworks', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Dor::ReleaseTag.new(to: 'PURL sitemap', release: true, date: '2023-03-27T10:00:00.000+00:00',
                                what: 'self')
          ]
        end

        it 'indexes release tags' do
          expect(doc).to eq(
            'released_to_ssim' => ['Searchworks', 'Earthworks', 'PURL sitemap'],
            'released_to_earthworks_dtpsidv' => '2016-11-16T22:52:35Z',
            'released_to_searchworks_dtpsidv' => '2021-05-12T21:05:21Z',
            'released_to_purl_sitemap_dtpsidv' => '2023-03-27T10:00:00Z'
          )
        end
      end

      context 'when releaseTags are not present' do
        it 'has no release tags' do
          expect(doc).to be_empty
        end
      end

      context 'when a collection with a collection releaseTag' do
        let(:release_tags) do
          [
            Dor::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00',
                                what: 'collection'),
            Dor::ReleaseTag.new(to: 'test_target', release: true, what: 'self')
          ]
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[Project test_target])
        end
      end
    end

    context 'with a parent collection' do
      let(:collection_druid) { 'druid:bc123fg4567' }
      let(:collection_druids) { [collection_druid] }

      context 'when the parent collection has self releaseTags' do
        let(:parent_collections_release_tags) do
          {
            collection_druid => [Dor::ReleaseTag.new(to: 'test_target', release: true,
                                                     date: '2016-12-21T17:31:18.000+00:00', what: 'self')]
          }
        end

        it 'indexes release tags' do
          expect(doc).to be_empty
        end
      end

      context 'when the parent collection has collection releaseTags' do
        let(:parent_collections_release_tags) do
          {
            collection_druid => [Dor::ReleaseTag.new(to: 'test_target', release: true,
                                                     date: '2016-12-21T17:31:18.000+00:00', what: 'collection')]
          }
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[test_target])
        end
      end

      context 'when the parent collection has releaseTags and the item has the same' do
        let(:release_tags) do
          [Dor::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'self')]
        end
        let(:parent_collections_release_tags) do
          {
            collection_druid => [Dor::ReleaseTag.new(to: 'test_target', release: true,
                                                     date: '2016-12-21T17:31:18.000+00:00',
                                                     what: 'collection')]
          }
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[test_target])
        end
      end

      context 'when the parent collection has release true and item has release false' do
        let(:release_tags) do
          [
            Dor::ReleaseTag.new(to: 'test_target', release: false, date: '2016-12-21T17:31:18.000+00:00',
                                what: 'self')
          ]
        end
        let(:parent_collections_release_tags) do
          {
            collection_druid => [Dor::ReleaseTag.new(to: 'test_target', release: true,
                                                     date: '2016-12-21T17:31:18.000+00:00',
                                                     what: 'collection')]
          }
        end

        it 'indexes release tags' do
          expect(doc).to be_empty
        end
      end

      context 'when releaseTags are not present' do
        it 'has no release tags' do
          expect(doc).not_to include('released_to_ssim')
        end
      end
    end
  end
  # rubocop:enable Style/StringHashKeys
end
