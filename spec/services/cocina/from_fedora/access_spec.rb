# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Access do
  subject(:access) { described_class.collection_props(item.rightsMetadata) }

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

  context 'with location access' do
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
              <location>spec</location>
            </machine>
          </access>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'location-based', readLocation: 'spec')
    end
  end

  context 'with no-download' do
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
              <world rule="no-download"/>
            </machine>
          </access>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world')
    end
  end

  context 'with an ODC license' do
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
      expect(access).to eq(access: 'citation-only', license: 'http://opendatacommons.org/licenses/by/1.0/')
    end
  end

  context 'with a CC license' do
    let(:xml) do
      <<~XML
        <rightsMetadata>
          <use>
            <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
            <machine type="creativeCommons">by-nc-nd</machine>
          </use>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'citation-only', license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/')
    end
  end

  context 'with a "none" license' do
    let(:xml) do
      <<~XML
        <rightsMetadata>
          <use>
            <human type="creativeCommons">no Creative Commons (CC) license</human>
            <machine type="creativeCommons">none</machine>
          </use>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'citation-only', license: 'http://cocina.sul.stanford.edu/licenses/none')
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
      expect(access).to eq(access: 'citation-only', useAndReproductionStatement: 'User agrees that, where applicable, stuff.')
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
      expect(access).to eq(access: 'citation-only', copyright: 'User agrees that, where applicable, stuff.')
    end
  end
end
