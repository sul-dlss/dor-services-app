# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::RelatedResource do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, related_resources: resources, druid: 'druid:vx162kw9911', id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  # 1. isReferencedBy relatedItem/part (510c) from druid:kf840zn4567
  context 'when it is isReferencedBy relatedItem/part' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "type": 'referenced by',
          "title": [
            {
              "value": 'Alden, J.E. European Americana'
            }
          ],
          "note": [
            {
              "value": '635/94',
              "type": 'location within source'
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
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Alden, J.E. European Americana</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number>635/94</number>
              </detail>
            </part>
          </relatedItem>
        </mods>
      XML
    end
  end

  # 2. constituent relatedItem/part adapted from vt758zn6912
  context 'when it is constituent relatedItem/part' do
    let(:resources) do
      [
        Cocina::Models::RelatedResource.new(
          "type": 'has part',
          "title": [
            {
              "value": '[Unidentified sextet]'
            }
          ],
          "note": [
            {
              "type": 'marker',
              "value": '02:T00:04:01',
              "displayLabel": 'Marker'
            }
          ]
        ),
        Cocina::Models::RelatedResource.new(
          "type": 'has part',
          "title": [
            {
              "value": 'Steal Away'
            }
          ],
          "note": [
            {
              "type": 'marker',
              "value": '03:T00:08:35',
              "displayLabel": 'Marker'
            }
          ]
        ),
        Cocina::Models::RelatedResource.new(
          "type": 'has part',
          "title": [
            {
              "value": 'Railroad Porter Blues'
            }
          ],
          "note": [
            {
              "type": 'marker',
              "value": '04:T00:15:35',
              "displayLabel": 'Marker'
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
          <relatedItem type="constituent">
            <titleInfo>
              <title>[Unidentified sextet]</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>02:T00:04:01</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Steal Away</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>03:T00:08:35</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Railroad Porter Blues</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>04:T00:15:35</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
        </mods>
      XML
    end
  end
end
