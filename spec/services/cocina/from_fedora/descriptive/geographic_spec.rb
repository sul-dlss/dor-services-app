# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Geographic do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with point coordinates' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
            <rdf:Description rdf:about="http://purl.stanford.edu/kk138ps4721">
              <dc:format>image/jpeg</dc:format>
              <dc:type>#{dc_type}</dc:type>
              <gmd:centerPoint>
                <gml:Point gml:id="ID">
                  <gml:pos>41.893367 12.483736</gml:pos>
                </gml:Point>
              </gmd:centerPoint>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    let(:expected_hash) do
      {
        "form": [
          {
            "value": 'image/jpeg',
            "type": 'media type',
            "source": {
              "value": 'IANA media type terms'
            }
          },
          {
            "value": 'Image',
            "type": 'media type',
            "source": {
              "value": 'DCMI Type Vocabulary'
            }
          }
        ],
        "subject": [
          {
            "structuredValue": [
              {
                "value": '41.893367',
                "type": 'latitude'
              },
              {
                "value": '12.483736',
                "type": 'longitude'
              }
            ],
            "type": 'point coordinates',
            "encoding": {
              "value": 'decimal'
            }
          }
        ]
      }
    end

    # MODS geo mapping spec not in /mappings/mods/geo_extension_spec.rb
    # Arcadia to add it there or make a different decision
    context 'when dc:type does not have the expected capitalization' do
      let(:dc_type) { 'image' }

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq([expected_hash])
        build.each { |model| Cocina::Models::DescriptiveGeographicMetadata.new(model) }
        expect(notifier).to have_received(:warn).with('dc:type normalized to <dc:type>Image</dc:type>', { type: 'image' })
      end
    end
  end

  context 'with a basic bounding box' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/cw222pt0426">
              <dc:format>image/jpeg</dc:format>
              <dc:type>#{dc_type}</dc:type>
              <gml:boundedBy>
                <gml:Envelope>
                  <gml:lowerCorner>-122.191292 37.4063388</gml:lowerCorner>
                  <gml:upperCorner>-122.149475 37.4435369</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    let(:expected_hash) do
      {
        form: [
          {
            value: 'image/jpeg',
            type: 'media type',
            source: {
              value: 'IANA media type terms'
            }
          },
          {
            value: 'Image',
            type: 'media type',
            source: {
              value: 'DCMI Type Vocabulary'
            }
          }
        ],
        subject: [
          {
            structuredValue: [
              {
                value: '-122.191292',
                type: 'west'
              },
              {
                value: '37.4063388',
                type: 'south'
              },
              {
                value: '-122.149475',
                type: 'east'
              },
              {
                value: '37.4435369',
                type: 'north'
              }
            ],
            type: 'bounding box coordinates',
            encoding: {
              value: 'decimal'
            }
          }
        ]
      }
    end

    # MODS geo mapping spec not in /mappings/mods/geo_extension_spec.rb
    # Arcadia to add it there or make a different decision
    context 'when dc:type does not have the expected capitalization' do
      let(:dc_type) { 'image' }

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq([expected_hash])
        build.each { |model| Cocina::Models::DescriptiveGeographicMetadata.new(model) }
        expect(notifier).to have_received(:warn).with('dc:type normalized to <dc:type>Image</dc:type>', { type: 'image' })
      end
    end
  end

  # MODS geo mapping spec not in /mappings/mods/geo_extension_spec.rb
  # Arcadia to add it there or make a different decision
  context 'with a bad PURL' do
    let(:dc_type) { 'Image' }
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
            <rdf:Description rdf:about="http://www.stanford.edu/kk138ps4721">
              <dc:format>image/jpeg</dc:format>
              <dc:type>#{dc_type}</dc:type>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'warns' do
      build
      expect(notifier).to have_received(:warn).with('rdf:about does not contain a correctly formatted PURL')
    end
  end

  # MODS geo mapping spec not in /mappings/mods/geo_extension_spec.rb
  # Arcadia to add it there or make a different decision
  context 'with an https PURL' do
    let(:dc_type) { 'Image' }
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
            <rdf:Description rdf:about="http://purl.stanford.edu/zg154pd4168">
              <dc:format>image/jpeg</dc:format>
              <dc:type>#{dc_type}</dc:type>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'does not warn' do
      build
    end
  end

  context 'without dc:format' do
    let(:dc_type) { 'Image' }
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
            <rdf:Description rdf:about="http://purl.stanford.edu/kk138ps4721">
              <dc:type>Image</dc:type>
              <gmd:centerPoint>
                <gml:Point gml:id="ID">
                  <gml:pos>41.893367 12.483736</gml:pos>
                </gml:Point>
              </gmd:centerPoint>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    let(:expected_hash) do
      {
        "form": [
          {
            "value": 'Image',
            "type": 'media type',
            "source": {
              "value": 'DCMI Type Vocabulary'
            }
          }
        ],
        "subject": [
          {
            "structuredValue": [
              {
                "value": '41.893367',
                "type": 'latitude'
              },
              {
                "value": '12.483736',
                "type": 'longitude'
              }
            ],
            "type": 'point coordinates',
            "encoding": {
              "value": 'decimal'
            }
          }
        ]
      }
    end

    it 'builds the cocina data structure' do
      expect(build).to eq([expected_hash])
    end
  end
end
