# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::CollectionAccess do
  subject(:collection_access) { described_class.props(collection.rightsMetadata) }

  let(:collection) do
    Dor::Collection.new
  end
  let(:rights_metadata_ds) { Dor::RightsMetadataDS.from_xml(xml) }

  before do
    allow(collection).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  describe 'access rights' do
    context 'when access other than public or dark' do
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
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as world' do
        expect(collection_access).to eq(access: 'world')
      end
    end

    context 'when dark' do
      let(:xml) do
        <<~XML
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

      it 'specifies access as dark' do
        expect(collection_access).to eq(access: 'dark')
      end
    end

    context 'when world' do
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

      it 'specifies access as world' do
        expect(collection_access).to eq(access: 'world')
      end
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
        expect(collection_access).to eq(access: 'dark', license: 'http://opendatacommons.org/licenses/by/1.0/')
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
        expect(collection_access).to eq(access: 'dark', useAndReproductionStatement: 'User agrees that, where applicable, stuff.')
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
        expect(collection_access).to eq(access: 'dark', copyright: 'User agrees that, where applicable, stuff.')
      end
    end
  end
end
