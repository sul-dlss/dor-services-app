# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::DROAccess do
  subject(:access) { described_class.props(item.rightsMetadata, embargo: embargo) }

  let(:embargo) { {} }

  let(:item) do
    Dor::Item.new
  end
  let(:rights_metadata_ds) { Dor::RightsMetadataDS.new.tap { |ds| ds.content = xml } }

  before do
    allow(item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  context 'with an embargo' do
    let(:embargo) { Cocina::FromFedora::Embargo.props(item.embargoMetadata) }
    # from https://argo.stanford.edu/view/druid:bb003dn0409

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

    before do
      embargo = Cocina::Models::Embargo.new(releaseDate: DateTime.parse('2029-02-28'), access: 'world', download: 'world', useAndReproductionStatement: 'in public domain')
      Cocina::ToFedora::EmbargoMetadataGenerator.generate(embargo_metadata: item.embargoMetadata, embargo: embargo)
    end

    it 'has embargo' do
      expect(access).to include(embargo: { access: 'world', download: 'world', releaseDate: '2029-02-28T00:00:00Z', useAndReproductionStatement: 'in public domain' })
    end
  end
end
