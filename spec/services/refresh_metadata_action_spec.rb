# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshMetadataAction do
  include Dry::Monads[:result]

  subject(:refresh) { described_class.run(identifiers: ['catkey:123'], cocina_object: cocina_object) }

  let(:druid) { 'druid:bc753qt7345' }
  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:description) do
    {
      title: [{ value: 'However am I going to be' }],
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A new map of Africa',
                            version: 1,
                            description: description,
                            identification: {},
                            access: {},
                            administrative: { hasAdminPolicy: apo_druid })
  end
  let(:updated_cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A new map of Africa',
                            version: 1,
                            description: {
                              title: [{ value: 'Paying for College' }],
                              purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
                            },
                            identification: {},
                            access: {},
                            administrative: { hasAdminPolicy: apo_druid })
  end

  let(:mods) do
    <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
        <titleInfo>
          <title>Paying for College</title>
        </titleInfo>
      </mods>
    XML
  end

  before do
    allow(MetadataService).to receive(:fetch).and_return(mods)
    allow(Honeybadger).to receive(:notify)
  end

  it 'gets the data and updates the cocina object' do
    expect(refresh).to eq(updated_cocina_object)
    expect(Honeybadger).not_to have_received(:notify)
  end

  context 'when fetch_metadata fails' do
    before do
      allow(MetadataService).to receive(:fetch).and_raise(SymphonyReader::ResponseError)
    end

    it 'gets the data and puts it in descMetadata and Honeybadger notifies' do
      expect { refresh }.to raise_error(SymphonyReader::ResponseError)
    end
  end

  context 'when fetch_metadata returns nil' do
    before do
      allow(MetadataService).to receive(:fetch).and_return(nil)
    end

    it 'returns a Dry::Monads::Result::Failure object' do
      expect(refresh).to be_a(Dry::Monads::Result::Failure)
    end
  end

  context 'when Descriptive.props returns nil' do
    before do
      allow(Cocina::FromFedora::Descriptive).to receive(:props).and_return(nil)
    end

    it 'returns a Dry::Monads::Result::Failure object' do
      expect(refresh).to be_a(Dry::Monads::Result::Failure)
    end
  end
end
