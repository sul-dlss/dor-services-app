# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::DROAccess do
  subject(:apply) { described_class.apply(item, access) }

  let(:item) do
    Dor::Item.new
  end

  context 'with an object lacking a license to start' do
    let(:item) do
      Dor::Item.new
    end
    let(:access) do
      Cocina::Models::DROAccess.new(
        license: 'http://opendatacommons.org/licenses/by/1.0/',
        copyright: 'New Copyright Statement',
        useAndReproductionStatement: 'New Use Statement'
      )
    end

    before do
      item.rightsMetadata.content = <<~XML
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
        </rightsMetadata>
      XML
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
            <human type="useAndReproduction">New Use Statement</human>
            <license>http://opendatacommons.org/licenses/by/1.0/</license>
          </use>
          <copyright>
            <human>New Copyright Statement</human>
          </copyright>
        </rightsMetadata>
      XML
    end
  end

  context 'with cdl access' do
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
            <license>https://creativecommons.org/licenses/by-nc-nd/3.0/</license>
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
            <license>http://opendatacommons.org/licenses/by/1.0/</license>
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
            <license>http://cocina.sul.stanford.edu/licenses/none</license>
          </use>
          <copyright>
            <human/>
          </copyright>
        </rightsMetadata>
      XML
    end
  end
end
