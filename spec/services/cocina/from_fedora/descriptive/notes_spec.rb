# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Notes do
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

  context 'with a simple note' do
    let(:xml) do
      <<~XML
        <note>This is a note.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a note.'
        }

      ]
    end
  end

  context 'with a note with a type' do
    let(:xml) do
      <<~XML
        <note type="preferred citation">This is the preferred citation.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is the preferred citation.',
          "type": 'preferred citation'
        }

      ]
    end
  end

  context 'with a note with a display label' do
    let(:xml) do
      <<~XML
        <note displayLabel="Conservation note">This is a conservation note.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a conservation note.',
          "displayLabel": 'Conservation note'
        }

      ]
    end
  end

  context 'with a multilingual note' do
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

  context 'with a single abstract' do
    let(:xml) do
      <<~XML
        <abstract>This is an abstract.</abstract>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is an abstract.',
          "type": 'summary'
        }

      ]
    end
  end

  context 'with a single abstract with a displayLabel' do
    let(:xml) do
      <<~XML
        <abstract displayLabel="Synopsis">This is a synopsis.</abstract>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a synopsis.',
          "type": 'summary',
          "displayLabel": 'Synopsis'
        }

      ]
    end
  end

  context 'with a simple table of contents' do
    let(:xml) do
      <<~XML
        <tableOfContents>Chapter 1. Chapter 2. Chapter 3.</tableOfContents>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'Chapter 1. Chapter 2. Chapter 3.',
          "type": 'table of contents'
        }

      ]
    end
  end

  context 'with a structured table of contents' do
    let(:xml) do
      <<~XML
        <tableOfContents>Chapter 1. -- Chapter 2. -- Chapter 3.</tableOfContents>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

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

      ]
    end
  end

  context 'with a multilingual table of contents' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_tableOfContents.txt#L33'
  end

  context 'with a table of contents with a display label' do
    let(:xml) do
      <<~XML
        <tableOfContents displayLabel="Contents">Content 1. Content 2.</tableOfContents>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'Content 1. Content 2.',
          "type": 'table of contents',
          "displayLabel": 'Contents'
        }

      ]
    end
  end
end
