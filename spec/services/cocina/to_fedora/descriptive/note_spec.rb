# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Note do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, notes: notes, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when note is nil' do
    let(:notes) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it has a multilingual note with script for one language' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "parallelValue": [
            {
              "value": 'This is a note.',
              "valueLanguage": {
                "code": 'eng',
                "source": {
                  "code": 'iso639-2b'
                },
                "valueScript": {
                  "code": 'Latn',
                  "source": {
                    "code": 'iso15924'
                  }
                }
              }
            },
            {
              "value": "C'est une note.",
              "valueLanguage": {
                "code": 'fre',
                "source": {
                  "code": 'iso639-2b'
                }
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
          <note lang="eng" script="Latn" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        </mods>
      XML
    end
  end
end
