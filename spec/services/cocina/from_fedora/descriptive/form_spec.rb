# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Form do
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

  context 'with an object with one type' do
    let(:xml) do
      <<~XML
        <typeOfResource>text</typeOfResource>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'text',
          "type": 'resource type',
          "source": {
            "value": 'MODS resource type'
          }
        }
      ]
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

  context 'with a typeOfResource with display label' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L106'
  end

  context 'with a single genre' do
    let(:xml) do
      <<~XML
        <genre>photographs</genre>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'photographs',
          "type": 'genre'
        }
      ]
    end
  end

  context 'with a multiple genre' do
    let(:xml) do
      <<~XML
        <genre>photographs</genre>
        <genre>prints</genre>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'photographs',
          "type": 'genre'
        },
        {
          "value": 'prints',
          "type": 'genre'
        }
      ]
    end
  end

  context 'with a genre with type' do
    let(:xml) do
      <<~XML
        <genre type="style">Art Deco</genre>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Art Deco',
          "type": 'style'
        }
      ]
    end
  end

  context 'with a genre with authority' do
    let(:xml) do
      <<~XML
        <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/"
          valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Photographs',
          "type": 'genre',
          "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
          "source": {
            "code": 'lcgft',
            "uri": 'http://id.loc.gov/authorities/genreForms/'
          }
        }
      ]
    end
  end

  context 'with a genre with usage' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L57'
  end

  context 'with a genre with multiple languages' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L74'
  end

  context 'with a genre with display label' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_genre.txt#L125'
  end

  context 'when there is a subject/cartographics node' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
            <scale>1:22,000,000</scale>
            <projection>Conic proj</projection>
          </cartographics>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '1:22,000,000',
          "type": 'map scale'
        },
        {
          "value": 'Conic proj',
          "type": 'map projection'
        }
      ]
    end
  end

  context 'when there is a subject/genre node' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
          <name type="personal">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo>
            <title>Hamlet</title>
          </titleInfo>
          <genre>Bibliographies</genre>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'Bibliographies',
          "type": 'genre'
        }
      ]
    end
  end
end
