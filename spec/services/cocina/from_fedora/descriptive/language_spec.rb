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

  context 'when single language with term, code, and authority uris' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="code">ara</languageTerm>
          <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="text">Arabic</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "code": 'ara',
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

  context 'with language term only' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm type="text">English</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'English'
        }
      ]
    end
  end

  context 'with language code only' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "code": 'eng',
          "source": {
            "code": 'iso639-2b'
          }
        }
      ]
    end
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

  context 'with multiple languages' do
    let(:xml) do
      <<~XML
        <language status="primary">
          <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
          <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
        </language>
        <language>
          <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">French</languageTerm>
          <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">fre</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'English',
          "code": 'eng',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
          },
          "status": 'primary'
        },
        {
          "value": 'French',
          "code": 'fre',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/fre',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
          }
        }
      ]
    end
  end

  context 'with script and authority' do
    let(:xml) do
      <<~XML
        <language>
          <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">Russian</languageTerm>
          <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">rus</languageTerm>
          <scriptTerm type="text" authority="iso15924">Cyrillic</scriptTerm>
          <scriptTerm type="code" authority="iso15924">Cyrl</scriptTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Russian',
          "code": 'rus',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/rus',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
          },
          "script": {
            "value": 'Cyrillic',
            "code": 'Cyrl',
            "source": {
              "code": 'iso15924'
            }
          }
        }
      ]
    end
  end

  context 'with script only' do
    let(:xml) do
      <<~XML
        <language>
          <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
          <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
        </language>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          "script": {
            "value": 'Latin',
            "code": 'Latn',
            "source": {
              "code": 'iso15924'
            }
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('languageTerm missing type')
    end
  end

  context 'with objectPart' do
    let(:xml) do
      <<~XML
        <language objectPart="liner notes">
          <languageTerm type="text">English</languageTerm>
        </language>
        <language objectPart="libretto">
          <languageTerm type="text">German</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'English',
          "appliesTo": [
            {
              "value": 'liner notes'
            }
          ]
        },
        {
          "value": 'German',
          "appliesTo": [
            {
              "value": 'libretto'
            }
          ]
        }
      ]
    end
  end

  context 'with displayLabel' do
    let(:xml) do
      <<~XML
        <language displayLabel="Translated to">
          <languageTerm type="text">English</languageTerm>
        </language>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'English',
          "displayLabel": 'Translated to'
        }
      ]
    end
  end

  context 'with authorityURI and valueURI for code' do
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

  context 'with authorityURI and valueURI for text' do
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
