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
end
