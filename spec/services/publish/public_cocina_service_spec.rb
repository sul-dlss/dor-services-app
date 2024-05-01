# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicCocinaService do
  subject(:create) { described_class.create(cocina_object) }

  context 'with a Collection' do
    let(:cocina_object) { build(:collection) }

    it 'copies the collection' do
      expect(create).to be_a Cocina::Models::Collection
    end
  end

  context 'with a DRO' do
    let(:publish_files) { false }
    let(:druid) { 'druid:bc123df4567' }

    let(:cocina_object) do
      build(:dro, id: druid).new(
        description: {
          title: [{ value: 'Constituent label &amp; A Special character' }],
          purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
        },
        structural: {
          contains: [
            {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/63a5295e-356e-428c-8ec7-894643efdeda',
              label: 'Page 1', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/f44c645d-c469-4345-b9b6-38eeb7f15dd3',
                    label: '50807230_0001.tif', filename: '50807230_0001.tif', size: 56_987_913,
                    version: 1, hasMimeType: 'image/tiff',
                    hasMessageDigests: [
                      { type: 'sha1', digest: '4af78fde7fd8099ac7e3fee3a58332b1d268d244' },
                      { type: 'md5', digest: '6618d3d35e6adbc5625405cd244f6bda' }
                    ],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false },
                    presentation: { height: 5360, width: 3544 }
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/8861aa09-416f-4890-8786-1dd45d2b6297',
                    label: '50807230_0001.jp2', filename: '50807230_0001.jp2', size: 3_575_822,
                    version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      { type: 'sha1', digest: '0a089200032d209e9b3e7f7768dd35323a863fcc' },
                      { type: 'md5', digest: 'c99fae3c4c53e40824e710440f08acb9' }
                    ],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: publish_files, sdrPreserve: false, shelve: false },
                    presentation: { height: 5360, width: 3544 }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/fdd60abb-76c0-4450-8276-0b6fb145dcc5',
              label: 'Page 2', version: 1,
              structural: {
                contains: [
                  { type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4c53e83b-6d45-435a-8323-299ded33800f',
                    label: '50807230_0002.tif', filename: '50807230_0002.tif', size: 31_525_443, version: 1,
                    hasMimeType: 'image/tiff',
                    hasMessageDigests: [
                      { type: 'sha1', digest: '46308444f201bec15857ac9338c2b6060f518ca5' },
                      { type: 'md5', digest: '010f88d1e40a6f81badde34e00c4ab5d' }
                    ],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false },
                    presentation: { height: 5496, width: 5736 } }, {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/bf2dd98c-8c9e-4802-ae28-8f60bb31b360',
                      label: '50807230_0002.jp2', filename: '50807230_0002.jp2', size: 5_920_056, version: 1,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        { type: 'sha1', digest: '4691466371691f774151574d1cf97ed73ba45d2c' },
                        { type: 'md5', digest: '08544fe844c45eebb552f280709af564' }
                      ],
                      access: { view: 'dark', download: 'none' },
                      administrative: { publish: false, sdrPreserve: false, shelve: false },
                      presentation: { height: 5496, width: 5736 }
                    }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/0b7db5f1-e12d-446c-acbc-a46361f5a06d',
              label: 'Page 3', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/8bbfdff7-1765-475a-a858-3b138c2eb31a',
                    label: '50807230_0003.tif', filename: '50807230_0003.tif', size: 31_525_443, version: 1,
                    hasMimeType: 'image/tiff',
                    hasMessageDigests: [
                      { type: 'sha1', digest: '6b1fc3618c2c195ccc99432491e3a864b2df02af' },
                      { type: 'md5', digest: '0b43cedb0c8beb030e7c0e87a7ae46ae' }
                    ],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false },
                    presentation: { height: 5496, width: 5736 }
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/0a532f3b-e473-4b68-b2fc-93436eb41240',
                    label: '50807230_0003.jp2', filename: '50807230_0003.jp2', size: 5_920_374, version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      { type: 'sha1', digest: '9c62ab0930a8e3540b7c151c3e52e8b7732e9c2e' },
                      { type: 'md5', digest: 'a9acee40e54bc6da6cee1388f7cc33e9' }
                    ],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: false, shelve: false },
                    presentation: { height: 5496, width: 5736 }
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [{ viewingDirection: 'left-to-right' }]
        }
      )
    end

    it 'updates the label' do
      expect(create.label).to eq 'Constituent label &amp; A Special character'
    end

    context 'when there are no published files' do
      it 'discards the non-published filesets and files' do
        expect(create.structural.contains.size).to eq 0
      end
    end

    context 'when there are published files' do
      let(:publish_files) { true }

      it 'keeps them' do
        expect(create.structural.contains.size).to eq 1
      end
    end

    context 'with an admin_policy' do
      let(:cocina_object) do
        build(:admin_policy, id: 'druid:bc123df4567')
      end

      it 'throws an exception' do
        expect { create }.to raise_error(RuntimeError, 'unexpected call to PublicCocinaService.build for druid:bc123df4567')
      end
    end

    context 'when there are multiple release tags per target' do
      subject(:release_tags) { create.administrative.releaseTags }

      let(:cocina_object) { build(:dro) }
      let(:druid) { cocina_object.externalIdentifier }

      before do
        ReleaseTag.create!(druid:, who: 'petucket', what: 'self', released_to: 'Searchworks', release: true)
        ReleaseTag.create!(druid:, who: 'petucket', what: 'self', released_to: 'Searchworks', release: false, created_at: 1.year.ago)
        ReleaseTag.create!(druid:, who: 'petucket', what: 'self', released_to: 'PURL sitemap', release: true)
      end

      it 'includes only the latest releaseData element from release tags for each target' do
        expect(release_tags.size).to eq 2
        expect(release_tags.map(&:release)).to eq [true, true]
        expect(release_tags.map(&:to)).to eq ['Searchworks', 'PURL sitemap']
      end
    end
  end
end
