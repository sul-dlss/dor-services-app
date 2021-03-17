# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyMetadataService do
  include Dry::Monads[:result]

  describe '.update_datastream_if_newer' do
    subject(:update) do
      described_class.update_datastream_if_newer(item: item,
                                                 datastream_name: 'descMetadata',
                                                 updated: updated,
                                                 content: content,
                                                 event_factory: event_factory)
    end

    let(:event_factory) { class_double(EventFactory, create: true) }
    let(:updated) { Time.zone.parse('2019-08-09T19:18:15Z') }
    let(:content) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>One title</title>
          </titleInfo>
        </mods>
      XML
    end
    let(:title) { ['One title'] }
    let(:item) do
      instance_double(Dor::Item, datastreams: { 'descMetadata' => datastream }, label: 'test label', pid: 'druid:bc123df4567')
    end
    let(:datastream) do
      instance_double(Dor::DescMetadataDS, createDate: create_date,
                                           dsid: 'descMetadata',
                                           pid: 'druid:bc123df4567',
                                           :content= => nil,
                                           mods_title: title)
    end

    before do
      allow(datastream).to receive(:ng_xml).and_return(Nokogiri::XML(content))
      allow(ModsValidator).to receive(:valid?).and_return(Success())
      allow(Cocina::DescriptionRoundtripValidator).to receive(:valid_from_fedora?).and_return(Success())
    end

    context 'with a new datastream' do
      let(:create_date) { nil }

      it 'updates the content' do
        update
        expect(datastream).to have_received(:content=).with(content)
        expect(event_factory).to have_received(:create)
        expect(ModsValidator).to have_received(:valid?)
        expect(Cocina::DescriptionRoundtripValidator).to have_received(:valid_from_fedora?)
      end
    end

    context 'with a datastream that is older than the content' do
      let(:create_date) { Time.zone.parse('2019-07-09T19:18:15Z') }

      it 'updates the content' do
        update
        expect(datastream).to have_received(:content=).with(content)
        expect(event_factory).to have_received(:create)
      end
    end

    context 'with an invalid datastream' do
      let(:create_date) { Time.zone.parse('2019-07-09T19:18:15Z') }
      let(:title) { [] }

      it 'raises an error' do
        expect { update }.to raise_error 'druid:bc123df4567 descMetadata missing required fields (<title>)'
      end
    end

    # TODO: Test roundtrip error. Cocina::FromFedora::Descriptive.props
  end
end
