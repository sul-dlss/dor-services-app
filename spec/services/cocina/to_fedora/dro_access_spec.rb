# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::DROAccess do
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

  context 'with a CC license' do
    let(:access) do
      Cocina::Models::DROAccess.new(license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/')
    end

    it 'builds the xml' do
      apply
      expect(item.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
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
            <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
            <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-nc-nd/3.0/">by-nc-nd</machine>
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

  context 'with an ODC license' do
    let(:access) do
      Cocina::Models::DROAccess.new(license: 'http://opendatacommons.org/licenses/by/1.0/')
    end

    it 'builds the xml' do
      apply
      expect(item.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
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
            <human type="creativeCommons"/>
            <machine type="creativeCommons" uri=""/>
            <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
            <machine type="openDataCommons" uri="http://opendatacommons.org/licenses/by/1.0/">odc-by</machine>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end
  end

  context 'with a "none" license' do
    let(:access) do
      Cocina::Models::DROAccess.new(license: 'http://cocina.sul.stanford.edu/licenses/none')
    end

    it 'builds the xml' do
      apply
      expect(item.rightsMetadata.ng_xml).to be_equivalent_to <<-XML
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
            <human type="creativeCommons">no Creative Commons (CC) license</human>
            <machine type="creativeCommons" uri="">none</machine>
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
end
