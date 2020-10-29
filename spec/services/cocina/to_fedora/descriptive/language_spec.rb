# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Language do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, languages: languages)
      end
    end
  end

  context 'when languages is nil' do
    let(:languages) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when single language with term, code, and authority uris' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "code": 'ara',
          "value": 'Arabic',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/ara',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="code">ara</languageTerm>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="text">Arabic</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'when it has a single language term only' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "value": 'English'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm type="text">English</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'when it has a single language code only' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "code": 'eng',
          "source": {
            "code": 'iso639-2b'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm type="code" authority="iso639-2b">eng</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with multiple languages' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "value": 'English',
          "code": 'eng',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
          },
          "status": 'primary'
        ),
        Cocina::Models::Language.new(
          "value": 'French',
          "code": 'fre',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/fre',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language status="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </language>
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">French</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre">fre</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with script and authority' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">Russian</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/rus">rus</languageTerm>
            <scriptTerm type="text" authority="iso15924">Cyrillic</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Cyrl</scriptTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with script only' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "script": {
            "value": 'Latin',
            "code": 'Latn',
            "source": {
              "code": 'iso15924'
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
          <language>
            <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with objectPart' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          {
            "value": 'English',
            "appliesTo": [
              {
                "value": 'liner notes'
              }
            ]
          }
        ),
        Cocina::Models::Language.new(
          {
            "value": 'German',
            "appliesTo": [
              {
                "value": 'libretto'
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
          <language objectPart="liner notes">
            <languageTerm type="text">English</languageTerm>
          </language>
          <language objectPart="libretto">
            <languageTerm type="text">German</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with displayLabel' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "value": 'English',
          "displayLabel": 'Translated to'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language displayLabel="Translated to">
            <languageTerm type="text">English</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with authorityURI and valueURI for code' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "code": 'ara',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/ara',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara">ara</languageTerm>
          </language>
        </mods>
      XML
    end
  end

  context 'with authorityURI and valueURI for text' do
    let(:languages) do
      [
        Cocina::Models::Language.new(
          "value": 'Arabic',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/ara',
          "source": {
            "code": 'iso639-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <language>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara">Arabic</languageTerm>
          </language>
        </mods>
      XML
    end
  end
end
