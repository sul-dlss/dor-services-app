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
          ]
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
              "value": "Shakespeare, William, 1564-1616",
              "type": "person"
            },
            {
              "value": "Homes and haunts",
              "type": "topic"
            }
          ]
        }
      ]
    end
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
end
