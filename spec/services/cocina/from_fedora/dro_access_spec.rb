# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::DROAccess do
  subject(:access) { described_class.props(rights_metadata_ds, embargo_metadata_ds) }

  let(:rights_metadata_ds) { Dor::RightsMetadataDS.from_xml(xml) }
  let(:embargo_metadata_ds) { Dor::EmbargoMetadataDS.new }

  context 'with an embargo' do
    let(:embargo) { Cocina::FromFedora::Embargo.props(item.embargoMetadata) }
    # from https://argo.stanford.edu/view/druid:bb003dn0409

    let(:xml) do
      <<~XML
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

    let(:embargo_metadata_ds) do
      datastream = Dor::EmbargoMetadataDS.new
      embargo = Cocina::Models::Embargo.new(releaseDate: DateTime.parse('2029-02-28'),
                                            access: 'world',
                                            download: 'none',
                                            useAndReproductionStatement: 'in public domain')
      Cocina::ToFedora::EmbargoMetadataGenerator.generate(embargo_metadata: datastream, embargo: embargo)
      datastream
    end

    it 'has embargo' do
      expect(access).to include(embargo: { access: 'world', download: 'none', releaseDate: '2029-02-28T00:00:00Z', useAndReproductionStatement: 'in public domain' })
    end
  end

  describe 'licenses and rights statements' do
    context 'with license' do
      let(:xml) do
        <<~XML
          <rightsMetadata>
            <use>
              <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
              <machine type="openDataCommons">odc-by</machine>
            </use>
          </rightsMetadata>
        XML
      end

      it 'builds the hash' do
        expect(access).to eq(access: 'dark', download: 'none', license: 'https://opendatacommons.org/licenses/by/1-0/')
      end
    end

    context 'with a use statement' do
      let(:xml) do
        <<~XML
          <rightsMetadata>
            <use>
              <human type="useAndReproduction">User agrees that, where applicable, stuff.</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'builds the hash' do
        expect(access).to eq(access: 'dark', download: 'none', useAndReproductionStatement: 'User agrees that, where applicable, stuff.')
      end
    end

    context 'with a copyright statement' do
      let(:xml) do
        <<~XML
          <rightsMetadata>
            <copyright>
              <human>User agrees that, where applicable, stuff.</human>
            </use>
          </rightsMetadata>
        XML
      end

      it 'builds the hash' do
        expect(access).to eq(access: 'dark', download: 'none', copyright: 'User agrees that, where applicable, stuff.')
      end
    end
  end
end
