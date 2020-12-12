# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
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

  context 'with invalid subelement <Topic>' do
    let(:xml) do
      <<~XML
        <subject authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <Topic>College students</Topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure (as if it was <topic> lowercase)' do
      expect(build).to eq [
        {
          "value": 'College students',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85028356',
          "source": {
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
    end

    it 'notifies Honeybadger' do
      allow(Honeybadger).to receive(:notify).once
      build
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] <subject> has <Topic>; normalized to "topic"', tags: 'data_error')
    end
  end

  context 'with invalid authority code and an authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="topic" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify).once
    end

    it 'ignores the invalid code and Honeybadger notifies' do
      expect(build).to eq [
        {
          "value": 'College students',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85028356',
          "source": {
            "uri": 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Subject has unknown authority code', tags: 'data_error')
    end
  end

  context 'with invalid authority code and no authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="topic" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify).once
    end

    it 'omits source and Honeybadger notifies' do
      expect(build).to eq [
        {
          "value": 'College students',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85028356'
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Subject has unknown authority code', tags: 'data_error')
    end
  end

  context 'with lcnaf authority code' do
    let(:xml) do
      <<~XML
        <subject authority="lcnaf" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify).once
    end

    it 'changes to naf and Honeybadger notifies' do
      expect(build).to eq [
        {
          "value": 'College students',
          "type": 'topic',
          "uri": 'http://id.loc.gov/authorities/subjects/sh85028356',
          "source": {
            "code": 'naf'
          }
        }
      ]
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] lcnaf authority code', tags: 'data_error')
    end
  end

  context 'with a single invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    it 'does not build subject element at all' do
      allow(Honeybadger).to receive(:notify)
      expect(build).to eq []
      expect(Honeybadger).to have_received(:notify).with("[DATA ERROR] Unexpected node type for subject: 'corporate'", tags: 'data_error')
    end
  end

  context 'with a valid element plus an invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    it 'drops the invalid subelement' do
      allow(Honeybadger).to receive(:notify)
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Cats',
              "type": 'topic'
            }
          ]
        }
      ]
      expect(Honeybadger).to have_received(:notify).with("[DATA ERROR] Unexpected node type for subject: 'corporate'", tags: 'data_error')
    end
  end

  context 'with multiple valid element plus an invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <topic>Dogs</topic>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    it 'drops the invalid subelement' do
      allow(Honeybadger).to receive(:notify)
      expect(build).to eq [
        {
          "structuredValue": [
            {
              "value": 'Cats',
              "type": 'topic'
            },
            {
              "value": 'Dogs',
              "type": 'topic'
            }
          ]
        }
      ]
      expect(Honeybadger).to have_received(:notify).with("[DATA ERROR] Unexpected node type for subject: 'corporate'", tags: 'data_error')
    end
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

  context 'with a single-term topic subject with non-lcsh authority on the subject' do
    let(:xml) do
      <<~XML
        <subject authority="mesh">
          <topic>Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Cats',
          "type": 'topic',
          "source": {
            "code": 'mesh'
          }
        }
      ]
    end
  end

  context 'with invalid subject "#N/A" authority' do
    let(:xml) do
      <<~XML
        <subject authority="#N/A">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure and logs an error' do
      allow(Honeybadger).to receive(:notify)
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
      expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] "#N/A" authority code', tags: 'data_error')
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

  context 'with a single-term topic subject with authority on the subject and topic' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">
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

    it 'builds (empty) cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with multiple subjects with cartographics, some with separate cartographics for scale vs coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <coordinates>W0750700 W0741200 N0443400 N0431200</coordinates>
          </cartographics>
        </subject>
        <subject>
          <cartographics>
            <scale>Scale ca. 1:126,720. 1 in. to 2 miles.</scale>
          </cartographics>
          <cartographics>
            <coordinates>(W 75&#x2070;07&#x2B9;00&#x2B9;--W 74&#x2070;12&#x2B9;00&#x2B9;/N 44&#x2070;34&#x2B9;00&#x2B9;--N 43&#x2070;12&#x2B9;00&#x2B9;)</coordinates>
          </cartographics>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          encoding: {
            value: 'DMS'
          },
          type: 'map coordinates',
          value: 'W0750700 W0741200 N0443400 N0431200'
        },
        {
          structuredValue: [
            {
              encoding: {
                value: 'DMS'
              },
              type: 'map coordinates',
              value: '(W 75⁰07ʹ00ʹ--W 74⁰12ʹ00ʹ/N 44⁰34ʹ00ʹ--N 43⁰12ʹ00ʹ)'
            }
          ]
        }
      ]
    end
  end

  context 'with single subject with multiple cartographics, none with coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <scale>Scale 1:100,000 :</scale>
          </cartographics>
          <cartographics>
            <projection>universal transverse Mercator proj.</projection>
          </cartographics>
        </subject>
      XML
    end

    it 'builds (empty) cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with a ISO19115TopicCategory subject' do
    let(:xml) do
      <<~XML
        <subject>
         <topic authority="ISO19115TopicCategory"
            authorityURI="http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode" valueURI="farming">Farming</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "source": {
            "code": 'ISO19115TopicCategory',
            "uri": 'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode'
          },
          "uri": 'farming',
          "value": 'Farming',
          "type": 'topic'
        }
      ]
    end
  end

  context 'with a temporal subject with encoding' do
    let(:xml) do
      <<~XML
        <subject>
          <temporal encoding="w3cdtf">1922-05-15</temporal>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '1922-05-15',
          "encoding": {
            "code": 'w3cdtf'
          },
          "type": 'time'
        }
      ]
    end
  end

  context 'with a temporal subject with range' do
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L695'
  end

  # Example 24
  context 'with a multilingual subject' do
    let(:xml) do
      <<~XML
        <subject lang="eng" altRepGroup="1">
          <topic>French New Wave</topic>
        </subject>
        <subject lang="fre" altRepGroup="1">
          <topic>Nouvelle Vague</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "parallelValue": [
            {
              "value": 'French New Wave',
              "valueLanguage": {
                "code": 'eng',
                "source": {
                  "code": 'iso639-2b'
                }
              }
            },
            {
              "value": 'Nouvelle Vague',
              "valueLanguage": {
                "code": 'fre',
                "source": {
                  "code": 'iso639-2b'
                }
              }
            }
          ],
          "type": 'topic'
        }
      ]
    end
  end

  context 'with a musical genre as topic' do
    # See https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/51
    xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_subject.txt#L754'
  end

  context 'with a occupation subject' do
    let(:xml) do
      <<~XML
        <subject>
          <occupation>Notaries</occupation>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Notaries',
          "type": 'occupation'
        }
      ]
    end
  end

  context 'with a display label' do
    let(:xml) do
      <<~XML
        <subject displayLabel="This is about">
          <topic>Stuff</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Stuff',
          "type": 'topic',
          "displayLabel": 'This is about'
        }
      ]
    end
  end
end
