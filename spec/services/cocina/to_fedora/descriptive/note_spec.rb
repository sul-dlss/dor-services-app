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

  context 'when it is a simple note' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'This is a note.'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note>This is a note.</note>
        </mods>
      XML
    end
  end

  context 'when it has a note with type' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'This is the preferred citation.',
          "type": 'preferred citation'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note type="preferred citation">This is the preferred citation.</note>
        </mods>
      XML
    end
  end

  context 'when it has a multilingual note' do
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

  context 'when it has a displayLabel' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'This is a conservation note.',
          "displayLabel": 'Conservation note'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note displayLabel="Conservation note">This is a conservation note.</note>
        </mods>
      XML
    end
  end

  # Example 1
  context 'when a simple table of contents' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Chapter 1. Chapter 2. Chapter 3.',
            "type": 'table of contents'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <tableOfContents>Chapter 1. Chapter 2. Chapter 3.</tableOfContents>
        </mods>
      XML
    end
  end

  # Example 2
  context 'when a structured table of contents' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "structuredValue": [
              {
                "value": 'Chapter 1.'
              },
              {
                "value": 'Chapter 2.'
              },
              {
                "value": 'Chapter 3.'
              }
            ],
            "type": 'table of contents'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <tableOfContents>Chapter 1. -- Chapter 2. -- Chapter 3.</tableOfContents>
        </mods>
      XML
    end
  end

  # Example 3
  context 'with a multilingual table of contents' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "parallelValue": [
              {
                "value": 'Chapter 1. Chapter 2. Chapter 3.',
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
                "value": 'Глава 1. Глава 2. Глава 3.',
                "valueLanguage":
                        {
                          "code": 'rus',
                          "source": {
                            "code": 'iso639-2b'
                          },
                          "valueScript": {
                            "code": 'Cyrl',
                            "source": {
                              "code": 'iso15924'
                            }
                          }
                        }
              }
            ],
            "type": 'table of contents'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <tableOfContents lang="eng" script="Latn" altRepGroup="1">Chapter 1. Chapter 2. Chapter 3.</tableOfContents>
          <tableOfContents lang="rus" script="Cyrl" altRepGroup="1">Глава 1. Глава 2. Глава 3.</tableOfContents>
        </mods>
      XML
    end
  end

  # Example 4
  context 'when a table of contents with a display label' do
    let(:notes) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": 'Content 1. Content 2.',
            "type": 'table of contents',
            "displayLabel": 'Contents'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <tableOfContents displayLabel="Contents">Content 1. Content 2.</tableOfContents>
        </mods>
      XML
    end
  end
end
