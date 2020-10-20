# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a single-term topic subject' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Cats',
          "type": 'topic'
        }
      ]
    end
  end

  context 'with a multi-term topic subject' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <temporal>1640</temporal>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": '1640',
              "type": 'time'
            }
          ]
        }
      ]
    end
  end

  context 'with a single-term topic subject with authority on the subject' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">
          <topic>Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Cats',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
    end
  end

  context 'with a single-term topic subject with authority on the topic' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Cats',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85021262',
          "source": {
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
    end
  end

  context 'with a multi-term topic subject with authority for set' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021263">
          <topic>Cats</topic>
          <topic>Anatomy</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a multi-term topic subject with authority for set but no valueURI' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <topic>Cats</topic>
          <topic>Anatomy</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a multi-term topic subject with authority for terms' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sj96004895">Behavior</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
          ],
          "source": {
            "code": 'lcsh'
          }
        }
      ]
    end
  end

  context 'with a multi-term topic subject with authority for both sets and terms' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh12345">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh23456">Horses</topic>
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh34567">History</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
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
        }
      ]
    end
  end

  context 'with a name subject' do
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

  context 'with a name subject with authority' do
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

  context 'with a name subject with authority missing authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="fast" valueURI="(OCoLC)fst00596994">
          <name type="corporate">
            <namePart>Biblioteka Polskiej Akademii Nauk w Krakowie</namePart>
          </name>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Biblioteka Polskiej Akademii Nauk w Krakowie',
          "type": 'person',
          "uri": '(OCoLC)fst00596994',
          "source": {
            "code": 'fast'
          }
        }
      ]
    end
  end

  context 'with a name subject with additional terms' do
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

  context 'with a name subject with additional terms and authority for set' do
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

  context 'with a name subject with multiple namePart elements' do
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

  context 'with a name subject with additional terms and authority for terms' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L247'
  end

  context 'with a name subject with additional terms and authority for terms and set' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L281'
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
            # TODO: Reviewing with Arcadia
            # "code": "naf",
            "code": 'lcsh',
            "uri": 'http://id.loc.gov/authorities/names/'
          }
        }
      ]
    end
  end

  context 'with a name-title subject with authority plus authority for name' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L351'
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
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L429'
  end

  context 'with a geographic subject subdivision' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <geographic>Europe</geographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Europe',
              "type": 'place'
            }
          ]
        }
      ]
    end
  end

  context 'with a hierarchical geographic subject subdivision' do
    let(:xml) do
      <<~XML
          <subject>
            <hierarchicalGeographic>
              <country>Austria</country>
              <city>Vienna</city>
            </hierarchicalGeographic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Austria',
              "type": 'country'
            },
            {
              "value": 'Vienna',
              "type": 'city'
            }
          ],
          "type": 'place'
        }
      ]
    end
  end

  context 'with a cartographic subject' do
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
          "value": 'E 72°--E 148°/N 13°--N 18°',
          "type": 'map coordinates',
          "encoding": {
            "value": 'DMS'
          }
        }
      ]
    end
  end

  context 'with a cartographic subject missing coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <scale>1:22,000,000</scale>
            <projection>Conic proj</projection>
          </cartographics>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with a geographic code subject' do
    let(:xml) do
      <<~XML
        <subject>
          <geographicCode authority="marcgac">n-us-md</geographicCode>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "code": 'n-us-md',
          "type": 'place',
          "source": {
            "code": 'marcgac'
          }
        }
      ]
    end
  end

  context 'with a geographic code and term' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L574'
  end

  context 'with a temporal subject with encoding' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L601'
  end

  context 'with a temporal subject with range' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L617'
  end

  context 'with a multilingual subject' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L643'
  end

  context 'with a musical genre as topic' do
    # See https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/51
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L672'
  end

  context 'with a display label' do
    # See https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/51
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L688'
  end
end
