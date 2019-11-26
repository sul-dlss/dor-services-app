# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyMetadataService do
  describe '.update_datastream_if_newer' do
    subject(:update) { described_class.update_datastream_if_newer(datastream: datastream, updated: updated, content: content) }

    let(:updated) { Time.zone.parse('2019-08-09T19:18:15Z') }
    let(:content) { '<descMetadata><foo/></descMetadata>' }
    let(:title) { ['One title'] }
    let(:datastream) do
      instance_double(Dor::DescMetadataDS, createDate: create_date,
                                           dsid: 'descMetadata',
                                           pid: 'druid:123',
                                           :content= => nil,
                                           mods_title: title)
    end

    context 'with a new datastream' do
      let(:create_date) { nil }

      it 'updates the content' do
        update
        expect(datastream).to have_received(:content=).with(content)
      end
    end

    context 'with a datastream that is older than the content' do
      let(:create_date) { Time.zone.parse('2019-07-09T19:18:15Z') }

      it 'updates the content' do
        update
        expect(datastream).to have_received(:content=).with(content)
      end
    end

    context 'with an invalid datastream' do
      let(:create_date) { Time.zone.parse('2019-07-09T19:18:15Z') }
      let(:title) { [] }

      it 'raises an error' do
        expect { update }.to raise_error 'druid:123 descMetadata missing required fields (<title>)'
      end
    end
  end
end
