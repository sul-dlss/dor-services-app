# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Form do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, forms: forms)
      end
    end
  end

  context 'when form is nil' do
    let(:forms) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  describe 'typeOfResource' do
    context 'with an object with one type' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'text',
            "type": 'resource type',
            "source": {
              "value": 'MODS resource type'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <typeOfResource>text</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with an object with multiple types' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L17'
    end

    context 'with an object with multiple types and one predominant' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L39'
    end

    context 'with a manuscript' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L62'
    end

    context 'with an attribute without a value' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L79'
    end

    context 'with a collection' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L89'
    end

    context 'with display label' do
      xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L106'
    end
  end

  describe 'genre' do
    context 'with a single value' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'photographs',
            "type": 'genre'
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre>photographs</genre>
          </mods>
        XML
      end
    end

    context 'with multiple values' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'photographs',
            "type": 'genre'
          ),
          Cocina::Models::DescriptiveValue.new(
            "value": 'prints',
            "type": 'genre'
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre>photographs</genre>
            <genre>prints</genre>
                      </mods>
        XML
      end
    end

    context 'with type' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'Art Deco',
            "type": 'style'
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="style">Art Deco</genre>
          </mods>
        XML
      end
    end

    context 'with authorities' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'Photographs',
            "type": 'genre',
            "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
            "source": {
              "code": 'lcgft',
              "uri": 'http://id.loc.gov/authorities/genreForms/'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/" valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
          </mods>
        XML
      end
    end

    context 'with usage' do
      xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L57'
    end

    context 'with multilingual' do
      xit 'TODO https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L74'
    end

    context 'with displayLabel' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'Art deco',
            "type": 'genre',
            "displayLabel": 'Style'
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre displayLabel="Style">Art deco</genre>
          </mods>
        XML
      end
    end
  end

  describe 'physicalDescription' do
    context 'with all elements' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'ink on paper',
            "type": 'form'
          ),
          Cocina::Models::DescriptiveValue.new(
            "value": 'access',
            "type": 'reformatting quality',
            "source": {
              "value": 'MODS reformatting quality terms'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            "value": 'image/jpeg',
            "type": 'media type',
            "source": {
              "value": 'IANA media types'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            "value": '1 sheet',
            "type": 'extent'
          ),
          Cocina::Models::DescriptiveValue.new(
            "value": 'reformatted digital',
            "type": 'digital origin',
            "source": {
              "value": 'MODS digital origin terms'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            "note": [
              {
                "value": 'Small tear at top right corner.',
                "displayLabel": 'Condition'
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
            <physicalDescription>
              <form>ink on paper</form>
              <reformattingQuality>access</reformattingQuality>
              <internetMediaType>image/jpeg</internetMediaType>
              <extent>1 sheet</extent>
              <digitalOrigin>reformatted digital</digitalOrigin>
              <note displayLabel="Condition">Small tear at top right corner.</note>
            </physicalDescription>
          </mods>
        XML
      end
    end

    context 'with multiple descriptions' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_physicalDescription.txt#L52'
    end

    context 'when form has authority' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
            "value": 'mezzotints (prints)',
            "type": 'form',
            "uri": 'http://vocab.getty.edu/aat/300041356',
            "source": {
              "code": 'aat',
              "uri": 'http://vocab.getty.edu/aat/'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <physicalDescription>
              <form authority="aat" authorityURI="http://vocab.getty.edu/aat/" valueURI="http://vocab.getty.edu/aat/300041356">mezzotints (prints)</form>
            </physicalDescription>
          </mods>
        XML
      end
    end

    context 'when it has displayLabel' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_physicalDescription.txt#L107'
    end
  end
end
