# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoReleaseService do
  let(:service) { described_class.new(item) }
  let(:embargo_release_date) { Time.now.utc - 100_000 }
  let(:release_access) do
    <<-EOXML
    <releaseAccess>
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
    </releaseAccess>
    EOXML
  end

  let(:rights_xml) do
    <<-EOXML
    <rightsMetadata objectId="druid:rt923jk342">
      <access type="discover">
        <machine>
          <world />
        </machine>
      </access>
      <access type="read">
        <machine>
          <group>stanford</group>
          <embargoReleaseDate>#{embargo_release_date.iso8601}</embargoReleaseDate>
        </machine>
      </access>
    </rightsMetadata>
    EOXML
  end

  describe '#release_embargo' do
    subject(:release) do
      service.release('application:embargo-release')
    end

    let(:embargo_ds) do
      eds = Dor::EmbargoMetadataDS.new
      eds.status = 'embargoed'
      eds.release_date = embargo_release_date
      eds.release_access_node = Nokogiri::XML(release_access) { |config| config.default_xml.noblanks }
      eds
    end
    let(:item) do
      embargo_item = Dor::Item.new
      embargo_item.datastreams['embargoMetadata'] = embargo_ds
      rds = Dor::RightsMetadataDS.new
      rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
      embargo_item.datastreams['rightsMetadata'] = rds
      embargo_item
    end

    it 'rights metadata has no embargo after Dor::Item.release_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      release
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to status released after Dor::Item.release_embargo' do
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'embargoed'
      release
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'released'
    end

    it 'sets the embargo status to released and indicates it is not embargoed' do
      release
      expect(embargo_ds.status).to eq('released')
      expect(item).not_to be_embargoed
    end

    context 'with rightsMetadata modifications' do
      it 'deletes embargoReleaseDate' do
        release
        rights = item.datastreams['rightsMetadata'].ng_xml
        expect(rights.at_xpath('//embargoReleaseDate')).to be_nil
      end

      context "when there is more than one <access type='read'> node in <releaseAccess>" do
        let(:release_access) do
          <<-EOXML
          <releaseAccess>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file id="restricted.doc"/>
              <machine>
                <group>stanford</group>
              </machine>
            </access>
          </releaseAccess>
          EOXML
        end

        it 'handles it' do
          release
          rights = item.datastreams['rightsMetadata'].ng_xml
          expect(rights.xpath("//rightsMetadata/access[@type='read']/file").size).to eq(1)
        end

        it 'replaces/adds access nodes with nodes from embargoMetadata/releaseAccess' do
          release
          rights = item.datastreams['rightsMetadata'].ng_xml
          expect(rights.xpath("//rightsMetadata/access[@type='read']").size).to eq(2)
          expect(rights.xpath("//rightsMetadata/access[@type='discover']").size).to eq(1)
          expect(rights.xpath("//rightsMetadata/access[@type='read']/machine/world").size).to eq(1)
          expect(rights.at_xpath("//rightsMetadata/access[@type='read' and not(file)]/machine/group")).to be_nil
        end
      end

      it 'marks the datastream as changed' do
        release
        expect(item.datastreams['rightsMetadata']).to be_changed
      end
    end

    it "writes 'embargo released' to event history" do
      release
      events = item.datastreams['events']
      events.find_events_by_type('embargo') do |who, _timestamp, message|
        expect(who).to eq 'application:embargo-release'
        expect(message).to eq 'Embargo released'
      end
    end
  end

  describe '#release_20_pct_vis' do
    subject(:release_20_pct_vis) do
      service.release_20_pct_vis('application:embargo-release')
    end

    let(:embargo_ds) do
      eds = Dor::EmbargoMetadataDS.new
      eds.status = 'embargoed'
      eds.twenty_pct_status = 'anything'
      eds.release_date = embargo_release_date
      eds.release_access_node = Nokogiri::XML(release_access) { |config| config.default_xml.noblanks }
      eds
    end

    let(:item) do
      embargo_item = Dor::Item.new
      embargo_item.datastreams['embargoMetadata'] = embargo_ds
      embargo_item.datastreams['rightsMetadata'].ng_xml = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }
      embargo_item
    end

    it 'rights metadata has no embargo after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      release_20_pct_vis
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to twenty_pct_status released after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.embargoMetadata.twenty_pct_status).to eql 'anything'
      release_20_pct_vis
      expect(item.embargoMetadata.twenty_pct_status).to eql 'released'
    end

    it 'sets the embargo status to released' do
      release_20_pct_vis
      expect(embargo_ds.twenty_pct_status).to eq 'released'
    end

    context 'with rightsMetadata modifications' do
      it 'replaces stanford group read access to world read access' do
        release_20_pct_vis
        rights = item.datastreams['rightsMetadata'].ng_xml
        expect(rights.xpath("//rightsMetadata/access[@type='read']").size).to eq 1
        expect(rights.xpath("//rightsMetadata/access[@type='discover']").size).to eq 1
        expect(rights.xpath("//rightsMetadata/access[@type='read']/machine/world").size).to eq 1
      end

      it 'marks the datastream as content changed' do
        release_20_pct_vis
        expect(item.datastreams['rightsMetadata']).to be_content_changed
      end
    end

    it "writes 'embargo released' to event history" do
      release_20_pct_vis
      events = item.datastreams['events']
      events.find_events_by_type('embargo') do |who, _timestamp, message|
        expect(who).to eq('application:embargo-release')
        expect(message).to eq('20% Visibility Embargo released')
      end
    end
  end

  describe '.release_items' do
    subject(:release_items) { described_class.release_items(query, &block) }

    let(:block) { proc {} }
    let(:query) { 'foo' }
    let(:response) do
      { 'response' => { 'numFound' => 1, 'docs' => [{ 'id' => 'druid:999' }] } }
    end

    before do
      allow(Dor::SearchService).to receive(:query).and_return(response)
    end

    context 'when the object is not in fedora' do
      before do
        allow(Dor).to receive(:find).and_raise(StandardError, 'Not Found')
        allow(Honeybadger).to receive(:notify)
      end

      it 'handles the error' do
        release_items
        expect(Honeybadger).to have_received(:notify)
      end
    end

    context 'when the object is in fedora' do
      let(:item) do
        i = Dor::Item.new
        rds = Dor::RightsMetadataDS.new
        rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
        i.datastreams['rightsMetadata'] = rds
        eds = Dor::EmbargoMetadataDS.new
        eds.content = Nokogiri::XML(embargo_xml) { |config| config.default_xml.noblanks }.to_s
        i.datastreams['embargoMetadata'] = eds
        i
      end

      let(:embargo_xml) do
        <<-EOXML
        <embargoMetadata>
          <status>embargoed</status>
          <releaseDate>#{embargo_release_date.iso8601}</releaseDate>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
          #{release_access}
        </embargoMetadata>
        EOXML
      end
      let(:client) { instance_double(Dor::Workflow::Client) }
      let(:event_factory) { { event_factory: EventFactory } }
      let(:close_params) { { description: 'embargo released', significance: 'admin' } }

      before do
        allow(Dor).to receive(:find).and_return(item)
        allow(VersionService).to receive(:can_open?).and_return(true)
        allow(VersionService).to receive(:open).with(item, event_factory)
        allow(VersionService).to receive(:close).with(item, close_params, event_factory)
        allow(item).to receive(:save!)
        allow(Honeybadger).to receive(:notify)
        allow(WorkflowClientFactory).to receive(:build).and_return(client)
        allow(client).to receive(:lifecycle).with('dor', 'druid:999', 'accessioned').and_return(Time.zone.now - 1.day)
      end

      it 'skips release if not accessioned' do
        allow(client).to receive(:lifecycle).with('dor', 'druid:999', 'accessioned').and_return(nil)
        release_items
        expect(VersionService).not_to have_received(:can_open?)
      end

      context 'when not openable' do
        before do
          allow(VersionService).to receive(:can_open?).with(item).and_return(false)
        end

        it 'skips release' do
          release_items
          expect(VersionService).to have_received(:can_open?).with(item)
          expect(VersionService).not_to have_received(:open)
        end
      end

      context 'when it is openable' do
        it 'is successful' do
          release_items
          expect(VersionService).to have_received(:can_open?).with(item)
          expect(VersionService).to have_received(:open).with(item, event_factory)
          expect(item).to have_received(:save!)
          expect(VersionService).to have_received(:close).with(item, close_params, event_factory)
        end
      end

      context 'when it cannot save the object' do
        before do
          allow(item).to receive(:save!).and_raise(StandardError, 'ActiveFedoraError, actually')
        end

        it 'handles error' do
          release_items
          exp_msg = 'Unable to release embargo for: druid:999'
          expect(Honeybadger).to have_received(:notify).with(/.*#{exp_msg}.*/, anything)
          expect(VersionService).not_to have_received(:close)
        end
      end
    end
  end
end
