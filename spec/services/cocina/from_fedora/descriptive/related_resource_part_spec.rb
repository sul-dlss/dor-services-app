# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::RelatedResource do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new(notifier: notifier) }

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

  # 1. isReferencedBy relatedItem/part (510c) from druid:kf840zn4567
  context 'with isReferencedBy relatedItem/part' do
    let(:xml) do
      <<~XML
        <relatedItem type="isReferencedBy">
          <titleInfo>
            <title>Alden, J.E. European Americana,</title>
          </titleInfo>
          <part>
            <detail type="part">
              <number>635/94</number>
            </detail>
          </part>
        </relatedItem>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
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

        }
      ]
    end
  end

  # 2. constituent relatedItem/part adapted from vt758zn6912
  context 'with constituent relatedItem/part' do
    let(:xml) do
      <<~XML
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
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
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
        },
        {
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
        },
        {
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
        }
      ]
    end
  end
end
