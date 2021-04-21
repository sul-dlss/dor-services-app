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
      EmbargoService.create(item: item,
                            release_date: DateTime.parse('2029-02-28'),
                            access: 'world',
                            use_and_reproduction_statement: 'in public domain')
    end

    it 'has embargo' do
      expect(access).to include(embargo: { access: 'world', releaseDate: '2029-02-28T00:00:00Z', useAndReproductionStatement: 'in public domain' })
    end
  end

  describe 'access and download rights' do
    context 'when controlled digital lending' do
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
                <cdl>
                  <group rule="no-download">stanford</group>
                </cdl>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as stanford with cdl = true and no download' do
        expect(access).to eq(access: 'stanford', controlledDigitalLending: true, download: 'none')
      end
    end

    context 'when stanford (no-download)' do
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
                <group rule="no-download">stanford</group>
              </machine>
            </access>
            <access type="read">
              <file>foo_bar.pdf</file>
              <machine>
                <world/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as stanford with no download' do
        expect(access).to eq(access: 'stanford', download: 'none')
      end
    end

    context 'when world (no-download)' do
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
            <access type="read">
              <file>foo_bar.pdf</file>
              <machine>
                <world/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as world with no download' do
        expect(access).to eq(access: 'world', download: 'none')
      end
    end
  end
end
