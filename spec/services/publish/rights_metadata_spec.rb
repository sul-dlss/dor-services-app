# frozen_string_literal: true

require 'rails_helper'

# rights objects for testing can be found at:
# https://argo-stage.stanford.edu/catalog?f%5Bnonhydrus_collection_title_ssim%5D%5B%5D=rights+examples
RSpec.describe Publish::RightsMetadata do
  subject(:service) { described_class.new(cocina_object, release_date) }

  describe '#create' do
    subject(:result) { service.create }

    let(:release_date) { nil }
    let(:description) do
      {
        title: [{ value: 'Constituent label &amp; A Special character' }],
        purl: 'https://purl.stanford.edu/bc123df4567'
      }
    end

    context 'when an object has an empty access node' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <none/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'outputs dark rights metadata' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is world' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds discover world and read world' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is world and includes use and copyright statements' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world',
                                  useAndReproductionStatement: 'Temporary use statement',
                                  copyright: 'Temporary copyright',
                                  license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
            <use><human type="useAndReproduction">Temporary use statement</human<license>https://creativecommons.org/licenses/by/4.0/legalcode</license></use>
            <copyright>
              <human>Temporary copyright</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      it 'adds discover world and read world with use and license' do
        expect(result.to_xml).to be_equivalent_to(Nokogiri::XML(expected).to_xml)
      end
    end

    context 'when an object is dark' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'dark',
                                  download: 'none'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <none />
              </machine>
            </access>
            <access type="read">
              <machine>
                <none />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds discover none and read none' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an embargo date is provided' do
      let(:release_date) { '2020-02-26T00:00:00+00:00' }
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'stanford',
                                  embargo: {
                                    releaseDate: release_date
                                  }
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world rule="no-download" />
                <embargoReleaseDate>2020-02-26T00:00:00+00:00</embargoReleaseDate>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds the embargo release date' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when read access is location based' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'location-based',
                                  download: 'location-based',
                                  readLocation: 'art'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <location>art</location>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'includes the location based access node' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when read access is location based and no download' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'location-based',
                                  download: 'none',
                                  readLocation: 'art'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <location rule="no-download">art</location>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds the embargo release date' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when object is location based and stanford no download' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'stanford',
                                  download: 'location-based',
                                  readLocation: 'art'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <location>art</location>
              </machine>
            </access>
            <access type="read">
              <machine>
                <group rule="no-download">stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'outputs read blocks for stanford and the location' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when object is location based and world no download' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'location-based',
                                  readLocation: 'art'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <location>art</location>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world rule="no-download" />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'outputs read blocks for world and the location' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is citation only' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'citation-only',
                                  download: 'none'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <none />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is controlled digital lending' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'stanford',
                                  download: 'none',
                                  controlledDigitalLending: true
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <cdl>
                  <group rule="no-download">stanford</group>
                </cdl>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is stanford no-download' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'stanford',
                                  download: 'none',
                                  controlledDigitalLending: false
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <group rule="no-download">stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is world no-download' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'stanford'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world rule="no-download" />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is stanford stanford' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'stanford',
                                  download: 'stanford'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when an object is open to the world but a file is no download' do
      let(:structural) do
        {
          contains: [{
            type: Cocina::Models::Vocab::Resources.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65',
            label: 'Image 1',
            version: 7,
            structural: {
              contains: [{
                type: Cocina::Models::Vocab.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65/placeholder.jp2',
                label: 'placeholder.jp2',
                filename: 'placeholder.jp2',
                size: 111_541_144,
                version: 7,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [],
                access: {
                  access: 'world',
                  download: 'none'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: false,
                  shelve: true
                }
              }]
            }
          }]
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end
      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <file>placeholder.jp2</file>
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'returns the appropriate rights metadata xml' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when object is world but the file is location based and stanford no download' do
      let(:structural) do
        {
          contains: [{
            type: Cocina::Models::Vocab::Resources.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65',
            label: 'Image 1',
            version: 7,
            structural: {
              contains: [{
                type: Cocina::Models::Vocab.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65/placeholder.jp2',
                label: 'placeholder.jp2',
                filename: 'placeholder.jp2',
                size: 111_541_144,
                version: 7,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [],
                access: {
                  access: 'stanford',
                  download: 'location-based',
                  readLocation: 'art'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: false,
                  shelve: true
                }
              }]
            }
          }]
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <file>placeholder.jp2</file>
              <machine>
                <location>art</location>
              </machine>
              <machine>
                <group rule="no-download">stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'outputs read blocks for stanford and the location' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when object is world but the file is location based and world no download' do
      let(:structural) do
        {
          contains: [{
            type: Cocina::Models::Vocab::Resources.file,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65',
            label: 'Image 1',
            version: 7,
            structural: {
              contains: [{
                type: Cocina::Models::Vocab.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/wf816pb3072/8043b03b-9ec3-44e9-8a93-00be030a5f65/placeholder.jp2',
                label: 'placeholder.jp2',
                filename: 'placeholder.jp2',
                size: 111_541_144,
                version: 7,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [],
                access: {
                  access: 'world',
                  download: 'location-based',
                  readLocation: 'm&m'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: false,
                  shelve: true
                }
              }]
            }
          }]
        }
      end
      let(:cocina_object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'A generic label',
                                version: 1,
                                description: description,
                                identification: {},
                                access: {
                                  access: 'world',
                                  download: 'world'
                                },
                                administrative: { hasAdminPolicy: 'druid:pp000pp0000' },
                                structural: structural)
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <file>placeholder.jp2</file>
              <machine>
                <location>m&amp;m</location>
              </machine>
              <machine>
                <world rule="no-download" />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'outputs read blocks for stanford and the location' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when a collection is world' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'A generic label',
                                       version: 1,
                                       description: description,
                                       identification: {},
                                       access: {
                                         access: 'world'
                                       },
                                       administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world />
              </machine>
            </access>
            <access type="read">
              <machine>
                <world />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds discover world and read world' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end

    context 'when a collection is dark' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'A generic label',
                                       version: 1,
                                       description: description,
                                       identification: {},
                                       access: {
                                         access: 'dark'
                                       },
                                       administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
      end

      let(:expected) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <none />
              </machine>
            </access>
            <access type="read">
              <machine>
                <none />
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'adds discover none and read none' do
        expect(result.to_xml).to be_equivalent_to(expected)
      end
    end
  end
end
