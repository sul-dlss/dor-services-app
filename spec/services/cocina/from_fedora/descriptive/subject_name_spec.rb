# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new(notifier: notifier) }

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

  context 'with one personal name' do
    let(:xml) do
      <<~XML
        <subject>
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Dunnett, Dorothy',
          "type": 'person'
        }
      ]
    end
  end

  context 'with authority' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79046044">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
          "type": 'person',
          "uri": 'http://id.loc.gov/authorities/names/n79046044',
          "source": {
            "code": 'naf',
            "uri": 'http://id.loc.gov/authorities/names/'
          }
        }
      ]
    end
  end

  context 'with authority missing authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="fast" valueURI="(OCoLC)fst00596994">
          <name type="corporate">
            <namePart>Biblioteka Polskiej Akademii Nauk w Krakowie</namePart>
          </name>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          "value": 'Biblioteka Polskiej Akademii Nauk w Krakowie',
          "type": 'organization',
          "uri": '(OCoLC)fst00596994',
          "source": {
            "code": 'fast'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('Value URI has unexpected value', { uri: '(OCoLC)fst00596994' })
    end
  end

  context 'with authority missing valueURI' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/">
            <namePart>Biblioteka Polskiej Akademii Nauk w Krakowie</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Biblioteka Polskiej Akademii Nauk w Krakowie',
          "type": 'organization',
          "source": {
            "code": 'naf',
            "uri": 'http://id.loc.gov/authorities/names/'
          }
        }
      ]
    end
  end

  context 'with additional terms' do
    let(:xml) do
      <<~XML
        <subject>
          <name type="personal">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <topic>Homes and haunts</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
      ]
    end
  end

  context 'with additional terms and authority for set' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
          <name type="personal">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <topic>Homes and haunts</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
      ]
    end
  end

  context 'with additional terms and authority for terms' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
      ]
    end
  end

  context 'with additional terms, authority for terms and set' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
      ]
    end
  end

  context 'with parts and genre subdivision' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal">
            <namePart>Debord, Guy</namePart>
            <namePart type="date">1931-1994</namePart>
          </name>
          <topic>Criticism and interpretation</topic>
        </subject>
      XML
    end

    it 'builds the cocina data model' do
      expect(build).to eq [
        {
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
        }

      ]
    end
  end

  context 'with multiple namePart elements and an inverted name' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal">
            <namePart>Nakahama, Manjir&#x14D;</namePart>
            <namePart type="date">1827-1898</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data model' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Nakahama, Manjirō',
              "type": 'name'
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
        }
      ]
    end
  end

  context 'with multiple namePart elements' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal">
            <namePart>Saki</namePart>
            <namePart type="date">1870-1916</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data model' do
      expect(build).to eq [
        {
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
        }
      ]
    end
  end

  context 'with a name-title subject with authority' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97075542">
          <name type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <titleInfo>
            <title>Lymond chronicles</title>
          </titleInfo>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a name-title subject with authority plus authority for name' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n97075542">
          <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50025011" type="personal">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <titleInfo>
            <title>Lymond chronicles</title>
          </titleInfo>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a name-title subject with additional terms including genre subdivision, authority for set' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
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

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a name-title subject with additional terms including genre subdivision, authority for terms' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n80008522">
            <title>Hamlet</title>
          </titleInfo>
          <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh99001362">Bibliographies</genre>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  # From druid:mt538yc4849
  context 'with a name-title subject where title has partNumber' do
    let(:xml) do
      <<~XML
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
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
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
        }
      ]
    end
  end

  context 'without name type' do
    let(:xml) do
      <<~XML
        <subject authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n81070667">
          <name>
            <namePart>Stanford University. Libraries.</namePart>
          </name>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          source:
            {
              code: 'naf',
              uri: 'http://id.loc.gov/authorities/names/'
            },
          type: 'name',
          uri: 'http://id.loc.gov/authorities/names/n81070667',
          value: 'Stanford University. Libraries.'
        }
      ]
      expect(notifier).to have_received(:warn).with('Subject contains a <name> element without a type attribute')
    end
  end

  context 'with an empty namePart' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <name type="corporate">
            <namePart/>
          </name>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'ignores the subject and warns' do
      expect(build).to eq []
      expect(notifier).to have_received(:warn).with('name/namePart missing value')
    end
  end

  context 'with invalid subject-name "#N/A" type' do
    let(:xml) do
      <<~XML
        <subject>
          <name type="#N/A" authority="#N/A" authorityURI="#N/A" valueURI="#N/A">
            <namePart>Hoveyda, Fereydoun</namePart>
          </name>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        { source: { uri: '#N/A' },
          type: 'name',
          uri: '#N/A',
          value: 'Hoveyda, Fereydoun' }
      ]
      expect(notifier).to have_received(:warn).with('Name type unrecognized', { type: '#N/A' })
      expect(notifier).to have_received(:warn).with('Subject has unknown authority code', { code: '#N/A' })
      expect(notifier).to have_received(:warn).with('Value URI has unexpected value', { uri: '#N/A' }).twice
    end
  end

  context 'with invalid subject-name "topic" type' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85129276">
          <name type="topic">
            <namePart>Student movements</namePart>
          </name>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure as if subject topic and warns' do
      expect(build).to eq [
        {
          "value": 'Student movements',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85129276',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('Name type unrecognized', { type: 'topic' })
    end
  end
end
