# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailService do
  let(:instance) { described_class.new(object) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#thumb' do
    subject(:thumb) { instance.thumb }

    context 'when a collection' do
      let(:object) { build(:collection) }

      it 'returns nil if there is no structural metadata' do
        expect(thumb).to be_nil
      end
    end

    context 'when an item' do
      let(:druid) { 'druid:bc123df4567' }
      let(:object) { build(:dro, id: druid).new(structural:) }

      context 'with no structural metadata' do
        let(:structural) { {} }

        it 'returns nil' do
          expect(thumb).to be_nil
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
          expect(thumb).to eq('bc123df4567/wt183gy6220_00_0001.jp2')
        end
      end

      context 'when an externalFile image resource is the only image' do
        let(:druid) { 'druid:cg767mn6478' }
        let(:member_object) do
          repository_object_version = build(:repository_object_version,
                                            external_identifier: druid,
                                            structural: {
                                              contains: [
                                                {
                                                  type: Cocina::Models::FileSetType.image,
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/cg767mn6478-2064a12c-c97f-4c66-85eb-1693fd5ae56f',
                                                  label: 'Object 1',
                                                  version: 1,
                                                  structural: {
                                                    contains: [
                                                      {
                                                        type: Cocina::Models::ObjectType.file,
                                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/cg767mn6478-2064a12c-c97f-4c66-85eb-1693fd5ae56f/2542A.tiff',
                                                        label: '2542A.tiff',
                                                        filename: '2542A.tiff',
                                                        hasMimeType: 'image/tiff',
                                                        size: 3_182_927,
                                                        version: 1,
                                                        access: {
                                                          view: 'world',
                                                          download: 'none'
                                                        },
                                                        administrative: {
                                                          publish: false,
                                                          sdrPreserve: true,
                                                          shelve: false
                                                        },
                                                        hasMessageDigests: []
                                                      },
                                                      {
                                                        type: Cocina::Models::ObjectType.file,
                                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/cg767mn6478-2064a12c-c97f-4c66-85eb-1693fd5ae56f/2542A.jp2',
                                                        label: '2542A.jp2',
                                                        filename: '2542A.jp2',
                                                        hasMimeType: 'image/jp2',
                                                        size: 11_043,
                                                        version: 1,
                                                        access: {
                                                          view: 'world',
                                                          download: 'none'
                                                        },
                                                        administrative: {
                                                          publish: true,
                                                          sdrPreserve: false,
                                                          shelve: true
                                                        },
                                                        hasMessageDigests: []
                                                      }
                                                    ]
                                                  }
                                                }
                                              ]
                                            })
          create(:repository_object, :with_repository_object_version, repository_object_version:,
                                                                      external_identifier: druid)
        end

        let(:structural) do
          {
            hasMemberOrders: [{
              members: [member_object.external_identifier]
            }]
          }
        end

        it 'returns the first image of the first member as the thumb' do
          expect(thumb).to eq('cg767mn6478/2542A.jp2')
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
          expect(thumb).to be_nil
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
          expect(thumb).to be_nil
        end
      end
    end
  end
end
