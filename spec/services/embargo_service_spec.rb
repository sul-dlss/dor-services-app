# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoService do
  subject(:embargo) do
    described_class.create(item: item, release_date: release_date, access: access)
  end

  let(:item) do
    Dor::Item.new.tap do |item|
      rights_datastream = Dor::RightsMetadataDS.new
      rights_datastream.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
      item.datastreams['rightsMetadata'] = rights_datastream
    end
  end

  let(:release_date) { DateTime.parse('2045-01-01') }

  let(:rights_xml) do
    <<-XML
    <?xml version="1.0"?>
    <rightsMetadata>
      <access type="discover">
        <machine>
          <world />
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

  RSpec.shared_examples 'common embargo' do
    it 'sets rightsMetadata to deny read' do
      embargo
      expect(item.datastreams['rightsMetadata'].ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <world/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <embargoReleaseDate>2045-01-01T00:00:00Z</embargoReleaseDate>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
      XML
    end
  end

  context 'when access is stanford' do
    let(:access) { 'stanford' }

    it_behaves_like 'common embargo'

    it 'sets embargoMetadata to embargoed and release access to stanford' do
      embargo
      expect(item.datastreams['embargoMetadata'].ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><world/></machine>
                </access>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end
  end

  context 'when access is world' do
    let(:access) { 'world' }

    it_behaves_like 'common embargo'

    it 'sets embargoMetadata to embargoed and release access to world' do
      embargo
      expect(item.datastreams['embargoMetadata'].ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><world/></machine>
                </access>
                <access type="read">
                  <machine>
                    <world />
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end

    context 'when use_and_reproduction_statement is provided' do
      before do
        described_class.create(item: item,
                               release_date: release_date,
                               access: access,
                               use_and_reproduction_statement: 'in public domain')
      end

      it 'sets use_and_reproduction_statement' do
        expect(item.embargoMetadata.use_and_reproduction_statement).to eq ['in public domain']
      end
    end
  end

  context 'when access is dark' do
    let(:access) { 'dark' }

    it_behaves_like 'common embargo'

    it 'sets embargoMetadata to embargoed and release access to none' do
      embargo
      expect(item.datastreams['embargoMetadata'].ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><world/></machine>
                </access>
                <access type="read">
                  <machine>
                    <none />
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end
  end
end
