# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Access do
  subject(:apply) { described_class.apply(collection, access) }

  let(:collection) do
    Dor::Collection.new
  end

  context 'with stanford access' do
    let(:access) do
      Cocina::Models::Access.new(access: 'stanford')
    end

    it 'builds the xml' do
      apply
      expect(collection.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
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
  end

  # NOTE: This example shows that when mapping back to Fedora we are REPLACING
  #       the existing license, not merely setting it
  context 'with an existing (ODC) license of a different class than the new one (CC)' do
    let(:access) do
      Cocina::Models::Access.new(license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/')
    end

    before do
      collection.rightsMetadata.content = <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <none/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <none/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction"/>
            <license>http://opendatacommons.org/licenses/by/1.0/</license>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'builds the xml, blanking the existing license' do
      apply
      expect(collection.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <none/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <none/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction"/>
            <license>https://creativecommons.org/licenses/by-nc-nd/3.0/</license>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end
  end
end
