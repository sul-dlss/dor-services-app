# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::GeoExtensionNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: 'druid:pf694bk4862') }

  context 'when normalizing geo PURL' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end

    it 'uses correct PURL' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing missing geo PURL' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description>
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
           <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
         </location>
        </mods>
      XML
    end

    it 'adds correct PURL' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
           <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
         </location>
        </mods>
      XML
    end
  end

  context 'when normalizing dc:type image' do
    context 'when image (lowercase I)' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
            <location>
              <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
            </location>
          </mods>
        XML
      end

      it 'fix capitalization (capitalizes I)' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
            <location>
              <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
            </location>
          </mods>
        XML
      end
    end

    context 'when Image (uppercase I)' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
            <location>
              <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
            </location>
          </mods>
        XML
      end

      it 'leaves capitalization' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
            <location>
              <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
            </location>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing gml:Point' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
                <gmd:centerPoint>
                  <gml:Point gml:id="ID">
                    <gml:pos>41.893367 12.483736</gml:pos>
                  </gml:Point>
                </gmd:centerPoint>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end

    it 'removes gml:ID' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
                <gmd:centerPoint>
                  <gml:Point>
                    <gml:pos>41.893367 12.483736</gml:pos>
                  </gml:Point>
                </gmd:centerPoint>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing empty rdf:resources' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:coverage rdf:resource="" dc:language="eng" dc:title="Southeast Asia"/>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end

    it 'removes the rdf:resource' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:coverage dc:language="eng" dc:title="Southeast Asia"/>
              </rdf:Description>
            </rdf:RDF>
          </extension>
          <location>
            <url usage="primary display">http://purl.stanford.edu/pf694bk4862</url>
          </location>
        </mods>
      XML
    end
  end
end
