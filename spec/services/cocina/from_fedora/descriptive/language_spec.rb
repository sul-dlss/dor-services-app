# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Language do
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

  context 'with language code only missing type' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm authority="iso639-2b">eng</languageTerm>
        </language>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          "code": 'eng',
          "source": {
            "code": 'iso639-2b'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('languageTerm missing type')
    end
  end

  context 'with authorityURI and valueURI for code only' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara">ara</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "code": 'ara',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/ara',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ]
    end
  end

  context 'with authorityURI and valueURI for text only' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara">Arabic</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Arabic',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/ara',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ]
    end
  end
end
