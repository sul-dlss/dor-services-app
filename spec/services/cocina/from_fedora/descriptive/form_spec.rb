# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Form do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

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

    context 'with a manuscript' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L62'
    end

    context 'with an attribute without a value' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L79'
    end

    context 'with a collection' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L89'
    end

    context 'with a typeOfResource with display label' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L106'
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
