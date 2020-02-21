# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoReleaseService do
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

    it 'rights metadata has no embargo after Dor::Item.release_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      item.release_embargo('ignored')
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to status released after Dor::Item.release_embargo' do
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'embargoed'
      item.release_embargo('ignored')
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'released'
    end
  end

  context 'when release_20_pct_vis_embargo' do
    let(:embargo_twenty_pct_xml) do
      <<-EOXML
      <embargoMetadata>
        <status>embargoed</status>
        <releaseDate>#{embargo_release_date.iso8601}</releaseDate>
        <twentyPctVisibilityStatus>anything</twentyPctVisibilityStatus>
        <twentyPctVisibilityReleaseDate>#{embargo_release_date.iso8601}</twentyPctVisibilityReleaseDate>
        #{release_access}
      </embargoMetadata>
      EOXML
    end
    let(:item) do
      i = Dor::Item.new
      rds = Dor::RightsMetadataDS.new
      rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['rightsMetadata'] = rds
      eds = Dor::EmbargoMetadataDS.new
      eds.content = Nokogiri::XML(embargo_twenty_pct_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['embargoMetadata'] = eds
      i
    end

    it 'rights metadata has no embargo after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      item.release_20_pct_vis_embargo('ignored')
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to twenty_pct_status released after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.embargoMetadata.twenty_pct_status).to eql 'anything'
      item.release_20_pct_vis_embargo('ignored')
      expect(item.embargoMetadata.twenty_pct_status).to eql 'released'
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

      before do
        allow(Dor).to receive(:find).and_return(item)
        allow(VersionService).to receive(:can_open?).and_return(true)
        allow(VersionService).to receive(:open).with(item)
        allow(VersionService).to receive(:close)
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
          expect(VersionService).to have_received(:open).with(item)
          expect(item).to have_received(:save!)
          expect(VersionService).to have_received(:close).with(item, description: 'embargo released', significance: 'admin')
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
