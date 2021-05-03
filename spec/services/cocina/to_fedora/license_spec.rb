# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::License do
  subject(:apply) { described_class.update(datastream, uri) }

  let(:datastream) do
    Dor::DefaultObjectRightsDS.new.tap { |ds| ds.content = datastream_xml }
  end

  context 'with cc0' do
    let(:uri) { 'https://creativecommons.org/share-your-work/public-domain/cc0/' }

    let(:datastream_xml) do
      <<~XML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction"/>
            <human type="creativeCommons"/>
            <machine type="creativeCommons" uri=""/>
            <human type="openDataCommons"/>
            <machine type="openDataCommons" uri=""/>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'writes the XML' do
      apply
      expect(datastream.ng_xml.xpath('//use')).to be_equivalent_to <<~XML
        <use>
           <human type="useAndReproduction"/>
           <license>https://creativecommons.org/share-your-work/public-domain/cc0/</license>
        </use>
      XML
    end
  end

  context 'with use without use and reproduction' do
    let(:uri) { 'https://creativecommons.org/share-your-work/public-domain/cc0/' }

    let(:datastream_xml) do
      <<~XML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
          <use>
            <human type="creativeCommons"/>
            <machine type="creativeCommons" uri=""/>
            <human type="openDataCommons"/>
            <machine type="openDataCommons" uri=""/>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'writes the XML' do
      apply
      expect(datastream.ng_xml.xpath('//use')).to be_equivalent_to <<~XML
        <use>
           <license>https://creativecommons.org/share-your-work/public-domain/cc0/</license>
        </use>
      XML
    end
  end
end
