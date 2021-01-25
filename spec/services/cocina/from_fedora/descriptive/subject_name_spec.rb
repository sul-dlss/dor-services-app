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
      expect(notifier).to have_received(:warn).with('"#N/A" authority code').twice
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
