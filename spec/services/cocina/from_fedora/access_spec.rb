# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Access do
  subject(:access) { described_class.collection_props(item.rightsMetadata) }

  let(:item) do
    Dor::Collection.new
  end
  let(:rights_metadata_ds) { Dor::RightsMetadataDS.from_xml(xml) }

  before do
    allow(item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  describe 'access rights' do
    context 'when citation-only' do
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

      it 'specifies access as citation-only' do
        expect(access).to eq(access: 'citation-only')
      end
    end

    context 'when controlled digital lending' do
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
                <cdl>
                  <group rule="no-download">stanford</group>
                </cdl>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as stanford with cdl = true' do
        expect(access).to eq(access: 'stanford', controlledDigitalLending: true)
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
        expect(access).to eq(access: 'dark')
      end
    end

    context 'when stanford' do
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
                <group>stanford</group>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      it 'specifies access as stanford' do
        expect(access).to eq(access: 'stanford')
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

      it 'specifies access as stanford' do
        expect(access).to eq(access: 'stanford')
      end
    end

    context 'when stanford + world (no-download)' do
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
                <group>stanford</group>
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

      it 'specifies access as world' do
        expect(access).to eq(access: 'world')
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
        expect(access).to eq(access: 'world')
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

      it 'specifies access as world' do
        expect(access).to eq(access: 'world')
      end
    end

    ['ars', 'art', 'hoover', 'm&m', 'music', 'spec'].each do |location|
      context "with location:#{location}" do
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
                  <location>#{CGI.escapeHTML(location)}</location>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        it "specifies access as location-based for #{location}" do
          expect(access).to eq(access: 'location-based', readLocation: location)
        end
      end

      context "with location:#{location} (no-download)" do
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
                  <location rule="no-download">#{CGI.escapeHTML(location)}</location>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        it "specifies access as location-based for #{location}" do
          expect(access).to eq(access: 'location-based', readLocation: location)
        end
      end

      context "with location:#{location} + stanford (no-download)" do
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
                  <location>#{CGI.escapeHTML(location)}</location>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <group rule="no-download">stanford</group>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        it "specifies access as stanford for #{location}" do
          expect(access).to eq(access: 'stanford', readLocation: location)
        end
      end

      context "with location:#{location} + world (no-download)" do
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
                  <location>#{CGI.escapeHTML(location)}</location>
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

        it "specifies access as world for #{location}" do
          expect(access).to eq(access: 'world', readLocation: location)
        end
      end
    end
  end
end
