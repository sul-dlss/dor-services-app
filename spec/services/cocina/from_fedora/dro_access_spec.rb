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

  context 'with useAndReproduction and no copyright' do
    # From https://argo.stanford.edu/view/druid:bb000kg4251
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
          <use>
            <human type="useAndReproduction">Property rights reside with the repository. Literary rights reside with the creators of the documents or their heirs. To obtain permission to publish or reproduce, please contact the Public Services Librarian of the Dept. of Special Collections (http://library.stanford.edu/spc).</human>
          </use>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           useAndReproductionStatement: 'Property rights reside with the repository. '\
                           'Literary rights reside with the creators of the documents or their heirs. ' \
                           'To obtain permission to publish or reproduce, please contact the Public ' \
                           'Services Librarian of the Dept. of Special Collections ' \
                           '(http://library.stanford.edu/spc).')
    end
  end

  describe 'with copyright' do
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
          <use>
            <human type="useAndReproduction">Official WTO documents are free for public use.</human>
            <human type="creativeCommons"/>
            <machine type="creativeCommons"/>
          </use>
          <copyright>
            <human>Copyright &#xA9; World Trade Organization</human>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           copyright: 'Copyright © World Trade Organization',
                           useAndReproductionStatement: 'Official WTO documents are free for public use.')
    end
  end

  describe 'with copyright but no use statement (contrived example)' do
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
          <copyright>
            <human>Copyright &#xA9; DLSS</human>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           copyright: 'Copyright © DLSS')
    end
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
      EmbargoService.create(item: item,
                            release_date: DateTime.parse('2029-02-28'),
                            access: 'world',
                            use_and_reproduction_statement: 'in public domain')
    end

    it 'has embargo' do
      expect(access).to include(embargo: { access: 'world', releaseDate: '2029-02-28T00:00:00Z', useAndReproductionStatement: 'in public domain' })
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
      expect(access).to include(license: 'http://opendatacommons.org/licenses/by/1.0/')
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
      expect(access).to include(license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/')
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
      expect(access).to include(license: 'http://cocina.sul.stanford.edu/licenses/none')
    end
  end

  describe 'access and download rights' do
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

      it 'specifies access as citation-only w/ no download' do
        expect(access).to eq(access: 'citation-only', download: 'none')
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

      it 'specifies access as stanford with cdl = true and no download' do
        expect(access).to eq(access: 'stanford', controlledDigitalLending: true, download: 'none')
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

      it 'specifies access as dark with no download' do
        expect(access).to eq(access: 'dark', download: 'none')
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

      it 'specifies access and download as stanford' do
        expect(access).to eq(access: 'stanford', download: 'stanford')
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

      it 'specifies access as world with stanford download' do
        expect(access).to eq(access: 'world', download: 'stanford')
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

      it 'specifies access and download as world' do
        expect(access).to eq(access: 'world', download: 'world')
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

        it "specifies access and download as location-based for #{location}" do
          expect(access).to eq(access: 'location-based', readLocation: location, download: 'location-based')
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

        it "specifies access as location-based for #{location} with no download" do
          expect(access).to eq(access: 'location-based', readLocation: location, download: 'none')
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

        it "specifies access as stanford and download as location-based for #{location}" do
          expect(access).to eq(access: 'stanford', readLocation: location, download: 'location-based')
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

        it "specifies access as world and download as location-based for #{location}" do
          expect(access).to eq(access: 'world', readLocation: location, download: 'location-based')
        end
      end
    end
  end
end
