# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Form do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  describe 'type of resource' do
    context 'with an object with one type' do
      let(:xml) do
        <<~XML
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'text',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with an object with multiple types' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L17'
    end

    context 'with an object with multiple types and one predominant' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L39'
    end

    # Example 4
    context 'with a manuscript' do
      let(:xml) do
        <<~XML
          <typeOfResource manuscript="yes">mixed material</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mixed material',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource types'
            }
          },
          {
            "value": 'manuscript',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with an attribute without a value' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L79'
    end

    context 'with a collection' do
      let(:xml) do
        <<~XML
          <typeOfResource collection="yes">mixed material</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mixed material',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource types'
            }
          },
          {
            "value": 'collection',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with a display label' do
      let(:xml) do
        <<~XML
          <typeOfResource displayLabel="Contains only">text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'text',
            "type": 'resource type',
            "displayLabel": 'Contains only',
            "source": {
              "value": 'MODS resource types'
            }
          }
        ]
      end
    end
  end

  describe 'genre' do
    context 'with a single genre' do
      let(:xml) do
        <<~XML
          <genre>photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'photographs',
            "type": 'genre'
          }
        ]
      end
    end

    context 'with multiple genres' do
      let(:xml) do
        <<~XML
          <genre>photographs</genre>
          <genre>prints</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'photographs',
            "type": 'genre'
          },
          {
            "value": 'prints',
            "type": 'genre'
          }
        ]
      end
    end

    context 'with  type' do
      let(:xml) do
        <<~XML
          <genre type="style">Art Deco</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Art Deco',
            "type": 'style'
          }
        ]
      end
    end

    context 'with authority' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms"
            valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
            "source": {
              "code": 'lcgft',
              "uri": 'http://id.loc.gov/authorities/genreForms/'
            }
          }
        ]
      end
    end

    context 'without valueURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "source": {
              "code": 'lcgft',
              "uri": 'http://id.loc.gov/authorities/genreForms/'
            }
          }
        ]
      end
    end

    context 'with authority missing authorityURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
            "source": {
              "code": 'lcgft'
            }
          }
        ]
      end
    end

    context 'with empty authority' do
      let(:xml) do
        <<~XML
          <genre authority="">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre'
          }
        ]
      end
    end

    context 'with usage' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L57'
    end

    context 'with multiple languages' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L74'
    end

    context 'with display label' do
      let(:xml) do
        <<~XML
          <genre displayLabel="Style">Art deco</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Art deco',
            "type": 'genre',
            "displayLabel": 'Style'
          }
        ]
      end
    end
  end

  describe 'subject' do
    # Example 19 from mods_to_cocina_subject.txt
    context 'when there is a subject/cartographics node' do
      let(:xml) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": '1:22,000,000',
            "type": 'map scale'
          },
          {
            "value": 'Conic proj',
            "type": 'map projection'
          }
        ]
      end
    end

    # Example 19b from mods_to_cocina_subject.txt
    context 'with a multiple cartographic subjects' do
      let(:xml) do
        <<~XML
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>(E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ)</coordinates>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>EPSG::4326</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Scale not given.',
            "type": 'map scale'
          },
          {
            "value": 'Custom projection',
            "type": 'map projection'
          },
          {
            "value": 'EPSG::4326',
            "type": 'map projection',
            "uri": 'http://opengis.net/def/crs/EPSG/0/4326',
            "source": {
              "code": 'EPSG'
            },
            "displayLabel": 'WGS84'
          }
        ]
      end
    end

    context 'when there is a subject/cartographics node with empty elements' do
      let(:xml) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale />
              <projection />
            </cartographics>
          </subject>
        XML
      end

      it 'ignores empty elements' do
        expect(build).to eq []
      end
    end

    context 'when there is a subject/genre node' do
      let(:xml) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <titleInfo>
              <title>Hamlet</title>
            </titleInfo>
            <genre>Bibliographies</genre>
          </subject>
        XML
      end

      it 'ignores the genre node' do
        expect(build).to eq []
      end
    end
  end

  # From https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/h2_cocina_mappings/h2_to_cocina_form.txt
  describe 'H2 work types & subtypes' do
    context 'with text / article' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Article</genre>
          <genre valueURI="http://vocab.getty.edu/aat/300048715" authority="aat">articles</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Text',
                type: 'type'
              },
              {
                value: 'Article',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'articles',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300048715',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with text / essay' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Essay</genre>
          <genre valueURI="http://id.loc.gov/authorities/genreForms/gf2014026094" authority="lcgft">Essays</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Text',
                type: 'type'
              },
              {
                value: 'Essay',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Essays',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2014026094',
            source: {
              code: 'lcgft'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with data / 3d model' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">3D model</genre>
          <genre>Three dimensional scan</genre>
          <typeOfResource>three dimensional object</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Data',
                type: 'type'
              },
              {
                value: '3D model',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Three dimensional scan',
            type: 'genre'
          },
          {
            value: 'three dimensional object',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with data / GIS' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">GIS</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2011026294">Geographic information systems</genre>
          <genre>dataset</genre>
          <typeOfResource>cartographic</typeOfResource>
          <typeOfResource>software, multimedia</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Data',
                type: 'type'
              },
              {
                value: 'GIS',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Geographic information systems',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2011026294',
            source: {
              code: 'lcgft'
            }
          },
          {
            value: 'dataset',
            type: 'genre'
          },
          {
            value: 'cartographic',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          },
          {
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with software / code, documentation' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Software</genre>
          <genre type="H2 subtype">Code</genre>
          <genre type="H2 subtype">Documentation</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300312188">programs (computer)</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300026413">technical manuals</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Software',
                type: 'type'
              },
              {
                value: 'Code',
                type: 'subtype'
              },
              {
                value: 'Documentation',
                type: 'subtype'
              }

            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'programs (computer)',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300312188',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'technical manuals',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300026413',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with other / dance notation' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Other</genre>
          <genre type="H2 subtype">Dance notation</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Other',
                type: 'type'
              },
              {
                value: 'Dance notation',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          }
        ]
      end
    end
  end

  describe 'physicalDescription' do
    context 'with all elements' do
      let(:xml) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <reformattingQuality>access</reformattingQuality>
            <internetMediaType>image/jpeg</internetMediaType>
            <extent>1 sheet</extent>
            <digitalOrigin>reformatted digital</digitalOrigin>
            <note displayLabel="Condition">Small tear at top right corner.</note>
            <note displayLabel="Material" type="material">Paper</note>
            <note displayLabel="Layout" type="layout">34 and 24 lines to a page</note>
            <note displayLabel="Height (mm)" type="dimensions">210</note>
            <note displayLabel="Width (mm)" type="dimensions">146</note>
            <note displayLabel="Collation" type="collation">1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).</note>
            <note displayLabel="Writing" type="handNote">change of hand</note>
            <note displayLabel="Foliation" type="foliation">ff. i + 1-51 + ii-iii</note>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'ink on paper',
            "type": 'form'
          },
          {
            "value": 'access',
            "type": 'reformatting quality',
            "source": {
              "value": 'MODS reformatting quality terms'
            }
          },
          {
            "value": 'image/jpeg',
            "type": 'media type',
            "source": {
              "value": 'IANA media types'
            }
          },
          {
            "value": '1 sheet',
            "type": 'extent'
          },
          {
            "value": 'reformatted digital',
            "type": 'digital origin',
            "source": {
              "value": 'MODS digital origin terms'
            }
          },
          {
            "note": [
              {
                "value": 'Small tear at top right corner.',
                "displayLabel": 'Condition'
              }
            ]
          },
          {
            note: [
              {
                value: 'Paper',
                displayLabel: 'Material',
                type: 'material'
              }
            ]
          },
          {
            note: [
              {
                value: '34 and 24 lines to a page',
                displayLabel: 'Layout',
                type: 'layout'
              }
            ]
          },
          {
            note: [
              {
                value: '210',
                displayLabel: 'Height (mm)',
                type: 'dimensions'
              }
            ]
          },
          {
            note: [
              {
                value: '146',
                displayLabel: 'Width (mm)',
                type: 'dimensions'
              }
            ]
          },
          {
            note: [
              {
                value: '1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).',
                displayLabel: 'Collation',
                type: 'collation'
              }
            ]
          },
          {
            note: [
              {
                value: 'change of hand',
                displayLabel: 'Writing',
                type: 'handNote'
              }
            ]
          },
          {
            note: [
              {
                value: 'ff. i + 1-51 + ii-iii',
                displayLabel: 'Foliation',
                type: 'foliation'
              }
            ]
          }
        ]
      end
    end

    context 'with multiple descriptions' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_physicalDescription.txt#L52'
    end

    context 'when form has authority' do
      let(:xml) do
        <<~XML
          <physicalDescription>
            <form authority="aat" authorityURI="http://vocab.getty.edu/aat/" valueURI="http://vocab.getty.edu/aat/300041356">mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mezzotints (prints)',
            "type": 'form',
            "uri": 'http://vocab.getty.edu/aat/300041356',
            "source": {
              "code": 'aat',
              "uri": 'http://vocab.getty.edu/aat/'
            }
          }
        ]
      end
    end

    context 'when note does not have displayLabel' do
      let(:xml) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <note>Small tear at top right corner.</note>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'ink on paper',
            "type": 'form'
          },
          {
            "note": [
              {
                "value": 'Small tear at top right corner.'
              }
            ]
          }
        ]
      end
    end

    context 'when physical description elsewhere in record' do
      let(:xml) do
        <<~XML
          <relatedItem type="original">
              <physicalDescription>
                 <form authority="marcform">print</form>
                 <extent>v. ; 24 cm.</extent>
              </physicalDescription>
           </relatedItem>
          <physicalDescription>
            <form>mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mezzotints (prints)',
            "type": 'form'
          }
        ]
      end
    end

    context 'when it has displayLabel' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_physicalDescription.txt#L107'
    end
  end
end
