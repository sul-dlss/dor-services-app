# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailService do
  let(:instance) { described_class.new(object) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#thumb' do
    subject { instance.thumb }

    context 'for a collection' do
      let(:object) { build(:collection) }

      it 'returns nil if there is no structural metadata' do
        expect(subject).to be_nil
      end
    end

    context 'for an item' do
      let(:druid) { 'druid:bc123df4567' }

      let(:object) { build(:dro, id: druid).new(structural:) }

      context 'with no structural metadata' do
        let(:structural) { {} }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when no specific thumbs are specified' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::FileSetType.image,
              externalIdentifier: 'wt183gy6220',
              label: 'Image 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::ObjectType.file,
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

        it 'returns the image as the thumb' do
          expect(subject).to eq('cg767mn6478_1/2542A.jp2')
        end
      end

      context 'when no thumb is identified' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::FileSetType.image,
              externalIdentifier: 'wt183gy6220',
              label: 'File 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::ObjectType.file,
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

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when file has no mime-type' do
        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::FileSetType.image,
              externalIdentifier: 'wt183gy6220',
              label: 'File 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'wt183gy6220_1',
                  label: 'File 1',
                  filename: 'some_file.pdf',
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

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
