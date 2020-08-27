# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Access do
  subject(:apply) { described_class.apply(item, access) }

  let(:item) do
    Dor::Item.new
  end

  describe 'with cdl access' do
    let(:access) do
      Cocina::Models::DROAccess.new(access: 'citation-only', controlledDigitalLending: true, download: 'none')
    end

    it 'builds the xml' do
      apply
      expect(item.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
        <?xml version="1.0"?>
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <cdl>
                  <group rule="no-download">stanford</group>
                </cdl>
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
         </xml>
      XML
    end
  end
end
