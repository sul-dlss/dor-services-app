# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::AccessBuilder do
  subject(:access) { described_class.build(item) }

  let(:item) do
    Dor::Collection.new
  end
  let(:rights_metadata_ds) { Dor::RightsMetadataDS.new.tap { |ds| ds.content = xml } }

  before do
    allow(item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  describe 'with world access' do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world')
    end
  end
end
