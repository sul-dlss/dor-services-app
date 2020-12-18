# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  subject(:xml) { writer.to_xml }

  let(:forms) { [] }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, subjects: subjects, forms: forms, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when subject is nil' do
    let(:subjects) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has an occupation subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            value: 'Notaries',
            type: 'occupation'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <occupation>Notaries</occupation>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a multi-term topic subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": '1640',
              "type": 'time'
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <topic>Cats</topic>
            <temporal>1640</temporal>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
            "source": {
              "code": 'lcsh',
              "uri": 'http://id.loc.gov/authorities/subjects/'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with authority but no authorityURI' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
            "source": {
              "code": 'lcsh'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic authority="lcsh" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with non-lcsh authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "source": {
              "code": 'mesh'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="mesh">
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a single-term topic subject with authority but no valueURI' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Cats',
            "type": 'topic',
            "source": {
              "code": 'lcsh'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a multi-term topic subject with authority for set' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Anatomy',
              "type": 'topic'
            }
          ],
          "uri": 'http://id.loc.gov/authorities/subjects/sh85021263',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021263">
            <topic>Cats</topic>
            <topic>Anatomy</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a multi-term topic subject with authority for set but no valueURI' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Anatomy',
              "type": 'topic'
            }
          ],
          "source": {
            "code": 'lcsh'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic>Cats</topic>
            <topic>Anatomy</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a multi-term topic subject with authority for terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Cats',
              "type": 'topic',
              "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/subjects/'
              }
            },
            {
              "value": 'Behavior',
              "type": 'topic',
              "uri": 'http://id.loc.gov/authorities/subjects/sj96004895',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sj96004895">Behavior</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has multi-term topic subject with authority for both set and terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Horses',
              "type": 'topic',
              "uri": 'http://id.loc.gov/authorities/subjects/sh23456',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/subjects/'
              }
            },
            {
              "value": 'History',
              "type": 'topic',
              "uri": 'http://id.loc.gov/authorities/subjects/sh34567',
              "source": {
                "code": 'lcsh',
                "uri": 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ],
          "uri": 'http://id.loc.gov/authorities/subjects/sh12345',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh12345">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh23456">Horses</topic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh34567">History</topic>
          </subject>
        </mods>
      XML
    end
  end

  # Example 19
  context 'when it has a cartographic subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        )
      ]
    end

    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1:22,000,000',
            "type": 'map scale'
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Conic proj',
            "type": 'map projection'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  # Example 19b
  context 'when it multiple cartographic subjects (mapped from ISO 19139)' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        )
      ]
    end

    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Scale not given.',
            "type": 'map scale'
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Custom projection',
            "type": 'map projection'
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'EPSG::4326',
            "type": 'map projection',
            "uri": 'http://opengis.net/def/crs/EPSG/0/4326',
            "source": {
              "code": 'EPSG'
            },
            "displayLabel": 'WGS84'
          }
        )

      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <projection>EPSG::4326</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a cartographic subject with valueURI and authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        )
      ]
    end

    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1:22,000,000',
            "type": 'map scale'
          }
        ),
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Conic proj',
            "type": 'map projection',
            "uri": 'http://opengis.net/def/crs/EPSG/0/4326',
            "source": {
              "code": 'EPSG'
            }
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326">
            <cartographics>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a cartographic subject without forms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a temporal subject with encoding' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": '1922-05-15',
          "encoding": {
            "code": 'w3cdtf'
          },
          "type": 'time'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <temporal encoding="w3cdtf">1922-05-15</temporal>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a temporal subject with range' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "value": '1890-06-11',
              "type": 'start'
            },
            {
              "value": '1894-03-19',
              "type": 'end'
            }
          ],
          "encoding": {
            "code": 'w3cdtf'
          },
          "type": 'time'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <temporal encoding="w3cdtf" point="start">1890-06-11</temporal>
            <temporal encoding="w3cdtf" point="end">1894-03-19</temporal>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a multilingual subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "parallelValue": [
            {
              "value": 'French New Wave',
              "valueLanguage": {
                "code": 'eng',
                valueScript: {
                  "code": 'Latn'
                }
              }
            },
            {
              "value": 'Nouvelle Vague',
              "valueLanguage": {
                "code": 'fre'
              }
            }
          ],
          "type": 'topic'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject lang="eng" script="Latn" altRepGroup="1">
            <topic>French New Wave</topic>
          </subject>
          <subject lang="fre" altRepGroup="1">
            <topic>Nouvelle Vague</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'with a parallel subject but different types' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "parallelValue": [
              {
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/subjects/'
                },
                "uri": 'http://id.loc.gov/authorities/subjects/sh85135212',
                "value": 'Tiber River (Italy)',
                "type": 'place'
              },
              {
                "source": {
                  "code": 'local'
                },
                "value": 'Tevere',
                "type": 'topic'
              },
              {
                "value": 'Tiber River',
                "type": 'name',
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/names/'
                },
                "uri": 'http://id.loc.gov/authorities/names/n97042879'
              }
            ]
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" altRepGroup="1">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85135212">Tiber River (Italy)</geographic>
          </subject>
          <subject authority="local" altRepGroup="1">
            <topic>Tevere</topic>
          </subject>
          <subject authority="lcsh" altRepGroup="1">
            <name authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97042879">
              <namePart>Tiber River</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a subject with lang and script' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "structuredValue": [
              {
                "value": 'Archives et documents',
                "type": 'topic'
              },
              {
                "value": 'Portraits',
                "type": 'topic'
              }
            ],
            "valueLanguage": {
              "code": 'fre',
              "source": {
                "code": 'iso639-2b'
              },
              valueScript: {
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            },
            "displayLabel": 'French archives'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject lang="fre" script="Latn" displayLabel="French archives">
            <topic>Archives et documents</topic>
            <topic>Portraits</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a musical genre as topic' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'String quartets',
            "type": 'topic',
            "source": {
              "code": 'lcsh'
            }
          }
        )
      ]
    end

    it 'see it builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic>String quartets</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a display label' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Stuff',
            "type": 'topic',
            "displayLabel": 'This is about'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject displayLabel="This is about">
            <topic>Stuff</topic>
          </subject>
        </mods>
      XML
    end
  end
end
