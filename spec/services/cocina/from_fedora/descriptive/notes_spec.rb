# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Notes do
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

  context 'with a multilingual note with a script for one language' do
    let(:xml) do
      <<~XML
        <note lang="eng" altRepGroup="1" script="Latn">This is a note.</note>
        <note lang="fre" altRepGroup="1">C'est une note.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "parallelValue": [
            {
              "value": 'This is a note.',
              "valueLanguage":
                {
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
              "valueLanguage":
                {
                  "code": 'fre',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
            }
          ]
        }
      ]
    end
  end

  context 'with an empty note' do
    let(:xml) do
      <<~XML
        <note />
      XML
    end

    it 'omits the note' do
      expect(build).to eq []
    end
  end

  context 'with an empty displayLabel' do
    let(:xml) do
      <<~XML
        <abstract displayLabel="">This is a synopsis.</abstract>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a synopsis.',
          "type": 'summary'
        }

      ]
    end
  end
end
