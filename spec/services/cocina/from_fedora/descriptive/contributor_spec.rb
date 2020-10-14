# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
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

  context 'when the role is missing the authority' do
    let(:xml) do
      <<~XML
        <name valueURI="corporate">
          <namePart>Selective Service System</namePart>
          <role>
            <roleTerm type="code">isb</roleTerm>
          </role>
        </name>
      XML
    end

    it 'raises an error' do
      expect { build }.to raise_error Cocina::Mapper::InvalidDescMetadata, './mods:role/mods:roleTerm[@type="code"] is missing required authority attribute'
    end
  end

  context 'with a personal name' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Dunnett, Dorothy</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Dunnett, Dorothy'
            }
          ],
          "type": 'person',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with a corporate name' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Dorothy L. Sayers Society</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Dorothy L. Sayers Society'
            }
          ],
          "type": 'organization',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with a family name' do
    let(:xml) do
      <<~XML
        <name type="family" usage="primary">
          <namePart>James family</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'James family'
            }
          ],
          "type": 'family',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with a conference name' do
    let(:xml) do
      <<~XML
        <name type="conference" usage="primary">
          <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Mystery Science Theater ConventioCon Expo Fest-o-rama'
            }
          ],
          "type": 'conference',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with additional subelements' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L75'
  end

  context 'with ordinal' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L140'
  end

  context 'with role' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L168'
  end

  context 'with authority' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L201'
  end

  context 'with multiple names, one primary' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L224'
  end

  context 'with multiple names, no primary' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L269'
  end

  context 'with single name, no primary (pseudonym)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L313'
  end

  context 'with multiple names with transliteration (name as value)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L331'
  end

  context 'with transliterated name with parts (name as structuredValue)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L428'
  end

  context 'with et al.' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L498'
  end

  context 'with displayLabel' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L521'
  end
end
