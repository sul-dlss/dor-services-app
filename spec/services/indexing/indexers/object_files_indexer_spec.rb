# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::ObjectFilesIndexer do
  let(:bare_druid) { 'cs178jh7817' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid, type: Cocina::Models::ObjectType.map).new(
      {
        structural:,
        access: {
          view: 'world',
          download: 'world'
        }
      }
    )
  end
  let(:indexer) { described_class.new(cocina:) }

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    context 'when the object contains file_sets' do
      let(:structural) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: '0001',
              label: '0001',
              version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_05_0001.jp2',
                    label: 'gw177fc7976_05_0001.jp2',
                    filename: 'gw177fc7976_05_0001.jp2',
                    size: 5_143_883,
                    version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: 'ca1eb0edd09a21f9dd9e3a89abc790daf4d04916'
                      },
                      {
                        type: 'md5',
                        digest: '3d3ff46d98f3d517d0bf086571e05c18'
                      }
                    ],
                    access: {
                      view: 'world',
                      download: 'world'
                    },
                    administrative: {
                      publish: true,
                      sdrPreserve: true,
                      shelve: true
                    },
                    presentation: {
                      height: 4580,
                      width: 5939
                    }
                  },
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_05_0001.gif',
                    label: 'gw177fc7976_05_0001.gif',
                    filename: 'gw177fc7976_05_0001.gif',
                    size: 4_128_877,
                    version: 1,
                    hasMimeType: 'image/gif',
                    use: 'derivative',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '61940d4fad097cba98a3e9dd9f12a90dde0be1ac'
                      },
                      {
                        type: 'md5',
                        digest: '406d5d80fdd9ecc0352d339badb4a8fb'
                      }
                    ],
                    access: {
                      view: 'dark',
                      download: 'none'
                    },
                    administrative: {
                      publish: false,
                      sdrPreserve: false,
                      shelve: false
                    },
                    presentation: {
                      height: 4580,
                      width: 5939
                    }
                  },
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_00_0001.tif',
                    label: 'gw177fc7976_00_0001.tif',
                    filename: 'gw177fc7976_00_0001.tif',
                    size: 81_630_420,
                    version: 1,
                    hasMimeType: 'image/tiff',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '12586b624540031bfa3d153299160c4885c3508c'
                      },
                      {
                        type: 'md5',
                        digest: '81ccd17bccf349581b779615e82a0366'
                      }
                    ],
                    access: {
                      view: 'dark',
                      download: 'none'
                    },
                    administrative: {
                      publish: false,
                      sdrPreserve: true,
                      shelve: false
                    },
                    presentation: {
                      height: 4580,
                      width: 5939
                    }
                  },
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_00_0002.tif',
                    label: 'gw177fc7976_00_0002.tif',
                    filename: 'gw177fc7976_00_0002.tif',
                    size: 81_630_420,
                    version: 1,
                    hasMimeType: 'image/tiff',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '12586b624540031bfa3d153299160c4885c3508c'
                      },
                      {
                        type: 'md5',
                        digest: '81ccd17bccf349581b779615e82a0366'
                      }
                    ],
                    access: {
                      view: 'dark',
                      download: 'none'
                    },
                    administrative: {
                      publish: false,
                      sdrPreserve: true,
                      shelve: false
                    },
                    presentation: {
                      height: 4580,
                      width: 5939
                    }
                  }
                ]
              }
            }
          ]
        }
      end

      it 'has the fields used by argo' do
        expect(doc).to include(
          'content_type_ssimdv' => 'map',
          'content_file_mimetypes_ssimdv' => ['image/jp2', 'image/gif', 'image/tiff'],
          'content_file_roles_ssimdv' => ['derivative'],
          'shelved_content_file_count_itsi' => 1,
          'resource_count_itsi' => 1,
          'content_file_count_itsi' => 4,
          'first_shelved_image_ss' => 'gw177fc7976_05_0001.jp2',
          'preserved_size_lpsi' => 168_404_723,
          'preserved_size_dbtsi' => 168_404_723, # TODO: remove https://github.com/sul-dlss/dor-services-app/issues/5604
          'human_preserved_size_ss' => '161 MB'
        )
      end
    end

    context 'when the object contains a file with no size' do
      let(:structural) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: '0001',
              label: '0001',
              version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_05_0001.jp2',
                    label: 'gw177fc7976_05_0001.jp2',
                    filename: 'gw177fc7976_05_0001.jp2',
                    version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: 'ca1eb0edd09a21f9dd9e3a89abc790daf4d04916'
                      },
                      {
                        type: 'md5',
                        digest: '3d3ff46d98f3d517d0bf086571e05c18'
                      }
                    ],
                    access: {
                      view: 'world',
                      download: 'world'
                    },
                    administrative: {
                      publish: true,
                      sdrPreserve: true,
                      shelve: true
                    }
                  },
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:cs178jh7817/gw177fc7976_05_0001.gif',
                    label: 'gw177fc7976_05_0001.gif',
                    filename: 'gw177fc7976_05_0001.gif',
                    size: 4_128_877,
                    version: 1,
                    hasMimeType: 'image/gif',
                    use: 'derivative',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '61940d4fad097cba98a3e9dd9f12a90dde0be1ac'
                      },
                      {
                        type: 'md5',
                        digest: '406d5d80fdd9ecc0352d339badb4a8fb'
                      }
                    ],
                    access: {
                      view: 'dark',
                      download: 'none'
                    },
                    administrative: {
                      publish: false,
                      sdrPreserve: true,
                      shelve: false
                    },
                    presentation: {
                      height: 4580,
                      width: 5939
                    }
                  }
                ]
              }
            }
          ]
        }
      end

      it 'ignores the nil sizes without erroring' do
        expect(doc).to include(
          'preserved_size_lpsi' => 4_128_877,
          'preserved_size_dbtsi' => 4_128_877, # TODO: remove https://github.com/sul-dlss/dor-services-app/issues/5604
          'human_preserved_size_ss' => '3.94 MB'
        )
      end
    end

    context 'when the object contains no file_sets' do
      let(:structural) { {} }

      it 'has the fields used by argo' do
        expect(doc).to include(
          'content_type_ssimdv' => 'map',
          'content_file_mimetypes_ssimdv' => [],
          'shelved_content_file_count_itsi' => 0,
          'resource_count_itsi' => 0,
          'content_file_count_itsi' => 0,
          'preserved_size_lpsi' => 0,
          'preserved_size_dbtsi' => 0, # TODO: remove https://github.com/sul-dlss/dor-services-app/issues/5604
          'human_preserved_size_ss' => '0 Bytes'
        )
      end
    end
  end
end
