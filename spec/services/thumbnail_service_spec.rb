# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailService do
  let(:instance) { described_class.new(object) }
  let(:druid) { 'druid:bc123df4567' }
  let(:description) do
    {
      title: [{ value: 'Constituent label &amp; A Special character' }],
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end

  describe '#thumb' do
    subject { instance.thumb }

    context 'for a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'Collection of new maps of Africa',
                                       version: 1,
                                       cocinaVersion: '0.0.1',
                                       access: {})
      end

      it 'returns nil if there is no structural metadata' do
        expect(subject).to be_nil
      end
    end

    context 'for an item' do
      let(:druid) { 'druid:bc123df4567' }
      let(:apo_druid) { 'druid:pp000pp0000' }

      context 'with no structural metadata' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: description,
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid })
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when no specific thumbs are specified' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::Vocab::Resources.image,
              externalIdentifier: 'wt183gy6220',
              label: 'Image 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::Vocab.file,
                  externalIdentifier: 'wt183gy6220_1',
                  label: 'Image 1',
                  filename: 'wt183gy6220_00_0001.jp2',
                  hasMimeType: 'image/jp2',
                  size: 3_182_927,
                  version: 1,
                  access: {},
                  administrative: {
                    publish: false,
                    sdrPreserve: false,
                    shelve: false
                  },
                  hasMessageDigests: []
                }]
              }
            }]
          }
        end
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: description,
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: structural)
        end

        it 'finds the first image as the thumb' do
          expect(subject).to eq('bc123df4567/wt183gy6220_00_0001.jp2')
        end
      end

      context 'when an externalFile image resource is the only image' do
        let(:structural) do
          {
            hasMemberOrders: [{
              members: ['cg767mn6478_1/2542A.jp2']
            }]
          }
        end
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: description,
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: structural)
        end

        it 'returns the image as the thumb' do
          expect(subject).to eq('cg767mn6478_1/2542A.jp2')
        end
      end

      context 'when no thumb is identified' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::Vocab::Resources.image,
              externalIdentifier: 'wt183gy6220',
              label: 'File 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::Vocab.file,
                  externalIdentifier: 'wt183gy6220_1',
                  label: 'File 1',
                  filename: 'some_file.pdf',
                  hasMimeType: 'file/pdf',
                  size: 3_182_927,
                  version: 1,
                  access: {},
                  administrative: {
                    publish: false,
                    sdrPreserve: false,
                    shelve: false
                  },
                  hasMessageDigests: []
                }]
              }
            }]
          }
        end
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: description,
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: structural)
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
