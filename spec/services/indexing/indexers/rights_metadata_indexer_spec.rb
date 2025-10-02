# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Indexing::Indexers::RightsMetadataIndexer do
  subject(:doc) { indexer.to_solr }

  let(:license) { 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
  let(:indexer) do
    described_class.new(cocina:)
  end

  context 'with a collection' do
    let(:access) { 'world' }

    let(:cocina) do
      build(:collection).new(
        access: {
          view: access,
          license:,
          copyright: 'Copyright © World Trade Organization',
          useAndReproductionStatement: 'Official WTO documents are free for public use.'
        }
      )
    end

    context 'with world access' do
      let(:access) { 'world' }

      it 'has the fields used by argo' do
        expect(doc).to include(
          'copyright_ssim' => 'Copyright © World Trade Organization',
          'use_statement_ssim' => 'Official WTO documents are free for public use.',
          'use_license_machine_ssi' => 'CC0-1.0',
          'rights_descriptions_ssim' => 'world', # TODO: Remove
          'rights_descriptions_ssimdv' => 'world'
        )
      end
    end

    context 'with dark access' do
      let(:access) { 'dark' }

      it 'has the fields used by argo' do
        expect(doc).to include(
          'copyright_ssim' => 'Copyright © World Trade Organization',
          'use_statement_ssim' => 'Official WTO documents are free for public use.',
          'use_license_machine_ssi' => 'CC0-1.0',
          'rights_descriptions_ssim' => 'dark', # TODO: Remove
          'rights_descriptions_ssimdv' => 'dark'
        )
      end
    end
  end
  # rubocop:enable Style/StringHashKeys

  context 'with an item' do
    let(:cocina) do
      build(:dro).new(
        access:,
        structural:
      )
    end
    let(:structural) { {} }
    let(:access) do
      {
        view: 'world',
        download: 'world',
        license:,
        copyright: 'Copyright © World Trade Organization',
        useAndReproductionStatement: 'Official WTO documents are free for public use.'
      }
    end

    # rubocop:disable Style/StringHashKeys
    it 'has the fields used by argo' do
      expect(doc).to include(
        'copyright_ssim' => 'Copyright © World Trade Organization',
        'use_statement_ssim' => 'Official WTO documents are free for public use.',
        'use_license_machine_ssi' => 'CC0-1.0',
        'rights_descriptions_ssim' => ['world'], # TODO: Remove
        'rights_descriptions_ssimdv' => ['world']
      )
    end
    # rubocop:enable Style/StringHashKeys

    describe 'rights descriptions (to remove)' do # TODO: Remove
      subject { doc['rights_descriptions_ssim'] }

      let(:structural) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
              label: 'Page 1',
              version: 5,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                    label: '50807230_0001.jp2',
                    filename: '50807230_0001.jp2',
                    size: 3_575_822,
                    version: 5,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                      },
                      {
                        type: 'md5',
                        digest: 'c99fae3c4c53e40824e710440f08acb9'
                      }
                    ],
                    access: file_access,
                    administrative: {
                      publish: false,
                      sdrPreserve: false,
                      shelve: false
                    },
                    presentation: {}
                  }
                ]
              }
            }
          ]
        }
      end

      context 'when citation only' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['citation'] }
      end

      context 'when controlled digital lending' do
        let(:access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: true
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq 'controlled digital lending' }
      end

      context 'when dark' do
        let(:access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['dark'] }
      end

      context 'when location' do
        context 'when downloadable' do
          let(:access) do
            {
              view: 'location-based',
              download: 'location-based',
              location: 'spec'
            }
          end

          let(:file_access) do
            {
              view: 'location-based',
              download: 'location-based',
              location: 'spec'
            }
          end

          it { is_expected.to eq ['location: spec'] }
        end

        context 'when not downloadable' do
          let(:access) do
            {
              view: 'location-based',
              download: 'none',
              location: 'spec'
            }
          end

          let(:file_access) do
            {
              view: 'location-based',
              download: 'none',
              location: 'spec'
            }
          end

          it { is_expected.to eq ['location: spec (no-download)'] }
        end
      end

      context 'when world readable and location download' do
        let(:access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'spec'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'spec'
          }
        end

        it { is_expected.to eq ['world (no-download)', 'location: spec'] }
      end

      context 'when stanford readable and location download' do
        let(:access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'spec'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'spec'
          }
        end

        it { is_expected.to eq ['stanford (no-download)', 'location: spec'] }
      end

      context 'when world readable and no-download' do
        let(:access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        it { is_expected.to eq ['world (no-download)'] }
      end

      context 'when stanford readable and no-download' do
        let(:access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq ['stanford (no-download)'] }
      end

      context 'when stanford, dark (file)' do
        # via https://argo.stanford.edu/view/druid:hz651dj0129
        let(:access) do
          {
            view: 'stanford',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['stanford', 'dark (file)'] }
      end

      context 'when stanford, world (file)' do
        # Via https://argo.stanford.edu/view/druid:bb142ws0723
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'stanford',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['stanford', 'world (file)'] }
      end

      context 'when citation, world (file)' do
        # https://argo.stanford.edu/view/druid:mq506jn2183
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end

        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['citation', 'world (file)'] }
      end

      context 'when world (no-download), stanford (no-download) (file)' do
        # via https://argo.stanford.edu/view/druid:cb810hh5010
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq ['world (no-download)', 'stanford (no-download) (file)'] }
      end

      context 'when two object level access. stanford, world (no-download), and world (file)' do
        # via https://argo.stanford.edu/view/druid:bd336ff4952
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'world',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['stanford', 'world (no-download)', 'world (file)'] }
      end

      context 'when file level access has a read location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'location-based',
            download: 'none',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'location: m&m (no-download) (file)'] }
      end

      context 'when file level access has stanford and a download location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'stanford (no-download) (file)', 'location: m&m (file)'] }
      end

      context 'when file level access has world and a download location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'world (no-download) (file)', 'location: m&m (file)'] }
      end

      context 'when file level access has world and stanford download' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'stanford'
          }
        end

        it { is_expected.to eq ['citation', 'world (no-download) (file)', 'stanford (file)'] }
      end
    end

    describe 'rights descriptions' do
      subject { doc['rights_descriptions_ssimdv'] }

      let(:structural) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
              label: 'Page 1',
              version: 5,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                    label: '50807230_0001.jp2',
                    filename: '50807230_0001.jp2',
                    size: 3_575_822,
                    version: 5,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [
                      {
                        type: 'sha1',
                        digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                      },
                      {
                        type: 'md5',
                        digest: 'c99fae3c4c53e40824e710440f08acb9'
                      }
                    ],
                    access: file_access,
                    administrative: {
                      publish: false,
                      sdrPreserve: false,
                      shelve: false
                    },
                    presentation: {}
                  }
                ]
              }
            }
          ]
        }
      end

      context 'when citation only' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['citation'] }
      end

      context 'when controlled digital lending' do
        let(:access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: true
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq 'controlled digital lending' }
      end

      context 'when dark' do
        let(:access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['dark'] }
      end

      context 'when location' do
        context 'when downloadable' do
          let(:access) do
            {
              view: 'location-based',
              download: 'location-based',
              location: 'spec'
            }
          end

          let(:file_access) do
            {
              view: 'location-based',
              download: 'location-based',
              location: 'spec'
            }
          end

          it { is_expected.to eq ['location: spec'] }
        end

        context 'when not downloadable' do
          let(:access) do
            {
              view: 'location-based',
              download: 'none',
              location: 'spec'
            }
          end

          let(:file_access) do
            {
              view: 'location-based',
              download: 'none',
              location: 'spec'
            }
          end

          it { is_expected.to eq ['location: spec (no-download)'] }
        end
      end

      context 'when world readable and location download' do
        let(:access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'spec'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'spec'
          }
        end

        it { is_expected.to eq ['world (no-download)', 'location: spec'] }
      end

      context 'when stanford readable and location download' do
        let(:access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'spec'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'spec'
          }
        end

        it { is_expected.to eq ['stanford (no-download)', 'location: spec'] }
      end

      context 'when world readable and no-download' do
        let(:access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        it { is_expected.to eq ['world (no-download)'] }
      end

      context 'when stanford readable and no-download' do
        let(:access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq ['stanford (no-download)'] }
      end

      context 'when stanford, dark (file)' do
        # via https://argo.stanford.edu/view/druid:hz651dj0129
        let(:access) do
          {
            view: 'stanford',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        it { is_expected.to eq ['stanford', 'dark (file)'] }
      end

      context 'when stanford, world (file)' do
        # Via https://argo.stanford.edu/view/druid:bb142ws0723
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'stanford',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['stanford', 'world (file)'] }
      end

      context 'when citation, world (file)' do
        # https://argo.stanford.edu/view/druid:mq506jn2183
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end

        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['citation', 'world (file)'] }
      end

      context 'when world (no-download), stanford (no-download) (file)' do
        # via https://argo.stanford.edu/view/druid:cb810hh5010
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        it { is_expected.to eq ['world (no-download)', 'stanford (no-download) (file)'] }
      end

      context 'when two object level access. stanford, world (no-download), and world (file)' do
        # via https://argo.stanford.edu/view/druid:bd336ff4952
        let(:structural) do
          {
            contains: [
              {
                type: Cocina::Models::FileSetType.page,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/d906da21-aca1-4b95-b7d1-c14c23cd93e6',
                label: 'Page 1',
                version: 5,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/4d88213d-f150-45ae-a58a-08b1045db2a0',
                      label: '50807230_0001.jp2',
                      filename: '50807230_0001.jp2',
                      size: 3_575_822,
                      version: 5,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '0a089200032d209e9b3e7f7768dd35323a863fcc'
                        },
                        {
                          type: 'md5',
                          digest: 'c99fae3c4c53e40824e710440f08acb9'
                        }
                      ],
                      access: file_access,
                      administrative: {
                        publish: false,
                        sdrPreserve: false,
                        shelve: false
                      },
                      presentation: {}
                    }
                  ]
                }
              }
            ]
          }
        end
        let(:access) do
          {
            view: 'world',
            download: 'stanford'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'world'
          }
        end

        it { is_expected.to eq ['stanford', 'world (no-download)', 'world (file)'] }
      end

      context 'when file level access has a read location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'location-based',
            download: 'none',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'location: m&m (no-download) (file)'] }
      end

      context 'when file level access has stanford and a download location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'stanford',
            download: 'location-based',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'stanford (no-download) (file)', 'location: m&m (file)'] }
      end

      context 'when file level access has world and a download location' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'm&m'
          }
        end

        it { is_expected.to eq ['citation', 'world (no-download) (file)', 'location: m&m (file)'] }
      end

      context 'when file level access has world and stanford download' do
        let(:access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end

        let(:file_access) do
          {
            view: 'world',
            download: 'stanford'
          }
        end

        it { is_expected.to eq ['citation', 'world (no-download) (file)', 'stanford (file)'] }
      end
    end
  end
end
