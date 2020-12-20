# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Subject do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, subjects: subjects, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when it has a name subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Dunnett, Dorothy',
            "type": 'person'
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
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a organization subject' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Stanford University',
            "type": 'organization',
            "uri": 'http://id.loc.gov/authorities/names/n79054636',
            "source": {
              "code": 'naf',
              "uri": 'http://id.loc.gov/authorities/names/'
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
            <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79054636">
              <namePart>Stanford University</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
            "type": 'person',
            "uri": 'http://id.loc.gov/authorities/names/n79046044',
            "source": {
              "code": 'naf',
              "uri": 'http://id.loc.gov/authorities/names/'
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
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79046044">
              <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with authority only' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
            "type": 'person',
            "source": {
              "code": 'naf'
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
            <name type="personal">
              <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person'
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic'
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
          <subject>
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the set' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person'
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic'
              }
            ],
            "uri": 'http://id.loc.gov/authorities/subjects/sh85120951',
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
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "code": 'naf',
                  "uri": 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic',
                "uri": 'http://id.loc.gov/authorities/subjects/sh99005711',
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/subjects/'
                }
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
          <subject authority="lcsh">
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the name' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "code": 'naf',
                  "uri": 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic'
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
          <subject>
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with multiple namePart elements and inverted full name' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "value": 'Nakahama, Manjirō',
              "type": 'inverted full name'
            },
            {
              "value": '1827-1898',
              "type": 'life dates'
            }
          ],
          "type": 'person',
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
            <name type="personal">
              <namePart>Nakahama, Manjir&#x14D;</namePart>
              <namePart type="date">1827-1898</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'with parts and genre subdivision' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "structuredValue": [
                {
                  "value": 'Debord, Guy',
                  "type": 'name'
                },
                {
                  "value": '1931-1994',
                  "type": 'life dates'
                }
              ],
              "type": 'person'
            },
            {
              "value": 'Criticism and interpretation',
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
            <name type="personal">
              <namePart>Debord, Guy</namePart>
              <namePart type="date">1931-1994</namePart>
            </name>
            <topic>Criticism and interpretation</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with multiple namePart elements' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "structuredValue": [
            {
              "value": 'Saki',
              "type": 'name'
            },
            {
              "value": '1870-1916',
              "type": 'life dates'
            }
          ],
          "type": 'person',
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
            <name type="personal">
              <namePart>Saki</namePart>
              <namePart type="date">1870-1916</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for the terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "code": 'naf',
                  "uri": 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic',
                "uri": 'http://id.loc.gov/authorities/subjects/sh99005711',
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/subjects/'
                }
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
          <subject authority="lcsh">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name subject with additional terms and authority for terms and set' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            structuredValue: [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "code": 'naf',
                  "uri": 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                "value": 'Homes and haunts',
                "type": 'topic',
                "uri": 'http://id.loc.gov/authorities/subjects/sh99005711',
                "source": {
                  "code": 'lcsh',
                  "uri": 'http://id.loc.gov/authorities/subjects/'
                }
              }
            ],
            "uri": 'http://id.loc.gov/authorities/subjects/sh85120951',
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
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name-title subject with authority' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Dunnett, Dorothy',
              "type": 'person'
            },
            {
              "value": 'Lymond chronicles',
              "type": 'title'
            }
          ],
          "uri": 'http://id.loc.gov/authorities/names/n97075542',
          "source": {
            "code": 'naf',
            "uri": 'http://id.loc.gov/authorities/names/'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97075542">
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name-title subject with authority plus authority for name' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Dunnett, Dorothy',
              "type": 'person',
              "uri": 'http://id.loc.gov/authorities/names/n50025011',
              "source": {
                "code": 'naf',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            },
            {
              "value": 'Lymond chronicles',
              "type": 'title'
            }
          ],
          "uri": 'http://id.loc.gov/authorities/names/n97075542',
          "source": {
            "code": 'naf',
            "uri": 'http://id.loc.gov/authorities/names/'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97075542">
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50025011" type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name-title subject with additional terms including genre subdivision, authority for set' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Shakespeare, William, 1564-1616',
              "type": 'person'
            },
            {
              "value": 'Hamlet',
              "type": 'title'
            },
            {
              "value": 'Bibliographies',
              "type": 'genre'
            }
          ],
          "uri": 'http://id.loc.gov/authorities/subjects/sh85120809',
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
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <titleInfo>
              <title>Hamlet</title>
            </titleInfo>
            <genre>Bibliographies</genre>
          </subject>
        </mods>
      XML
    end
  end

  context 'when it has a name-title subject with additional terms including genre subdivision, authority for terms' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          structuredValue: [
            {
              "value": 'Shakespeare, William, 1564-1616',
              "type": 'person',
              "uri": 'http://id.loc.gov/authorities/names/n78095332',
              "source": {
                "code": 'naf',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            },
            {
              "value": 'Hamlet',
              "type": 'title',
              "uri": 'http://id.loc.gov/authorities/names/n80008522',
              "source": {
                "code": 'naf',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            },
            {
              "value": 'Bibliographies',
              "type": 'genre',
              "uri": 'http://id.loc.gov/authorities/subjects/sh99001362',
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
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <titleInfo authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522">
              <title>Hamlet</title>
            </titleInfo>
            <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99001362">Bibliographies</genre>
          </subject>
        </mods>
      XML
    end
  end

  # From druid:mt538yc4849
  context 'with a name-title subject where title has partNumber' do
    let(:subjects) do
      [
        Cocina::Models::DescriptiveValue.new(
          "source": {
            "code": 'lcsh'
          },
          "structuredValue": [
            {
              "structuredValue": [
                {
                  "value": 'California.',
                  "type": 'name'
                },
                {
                  "value": 'Sect. 7570.',
                  "type": 'name'
                }
              ],
              "type": 'organization'
            },
            {
              "structuredValue": [
                {
                  "value": 'Government Code',
                  "type": 'main title'
                },
                {
                  "value": 'Sect. 7570',
                  "type": 'part number'
                }
              ],
              "type": 'title'
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
            <name type="corporate">
              <namePart>California.</namePart>
              <namePart>Sect. 7570.</namePart>
            </name>
            <titleInfo>
              <title>Government Code</title>
              <partNumber>Sect. 7570</partNumber>
            </titleInfo>
          </subject>
        </mods>
      XML
    end
  end
end
