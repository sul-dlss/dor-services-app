# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Form do
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

  describe 'typeOfResource' do
    context 'with empty element' do
      let(:xml) do
        <<~XML
          <typeOfResource></typeOfResource>
          <typeOfResource/>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq []
      end
    end
  end

  describe 'genre' do
    context 'with authority missing valueURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "source": {
              "code": 'lcgft',
              "uri": 'http://id.loc.gov/authorities/genreForms/'
            }
          }
        ]
      end
    end

    context 'with authority missing authorityURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
            "source": {
              "code": 'lcgft'
            }
          }
        ]
      end
    end

    context 'with empty authority' do
      let(:xml) do
        <<~XML
          <genre authority="">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre'
          }
        ]
      end
    end
  end

  describe 'subject' do
    context 'when there is a subject/cartographics node with empty elements' do
      let(:xml) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale />
              <projection />
            </cartographics>
          </subject>
        XML
      end

      it 'ignores empty elements' do
        expect(build).to eq []
      end
    end

    context 'when there is a subject/genre node' do
      let(:xml) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
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

      it 'ignores the genre node' do
        expect(build).to eq []
      end
    end
  end

  describe 'physicalDescription' do
    context 'when note does not have displayLabel' do
      let(:xml) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <note>Small tear at top right corner.</note>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'ink on paper',
            "type": 'form'
          },
          {
            "note": [
              {
                "value": 'Small tear at top right corner.'
              }
            ]
          }
        ]
      end
    end

    context 'when physical description elsewhere in record' do
      let(:xml) do
        <<~XML
          <relatedItem type="original">
              <physicalDescription>
                 <form authority="marcform">print</form>
                 <extent>v. ; 24 cm.</extent>
              </physicalDescription>
           </relatedItem>
          <physicalDescription>
            <form>mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mezzotints (prints)',
            "type": 'form'
          }
        ]
      end
    end
  end
end
