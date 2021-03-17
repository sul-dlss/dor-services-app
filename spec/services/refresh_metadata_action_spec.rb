# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshMetadataAction do
  include Dry::Monads[:result]

  subject(:refresh) { described_class.run(identifiers: ['catkey:123'], fedora_object: item) }

  let(:item) { Dor::Item.new }

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

  it 'gets the data and puts it in descMetadata' do
    expect(refresh).not_to be_nil
    expect(item.descMetadata.ng_xml).to be_equivalent_to Nokogiri::XML(mods)
    expect(Honeybadger).not_to have_received(:notify)
  end

  context 'when validation fails' do
    before do
      allow(Cocina::DescriptionRoundtripValidator).to receive(:valid_from_fedora?).and_return(Failure())
    end

    it 'gets the data and puts it in descMetadata and Honeybadger notifies' do
      expect(refresh).not_to be_nil
      expect(item.descMetadata.ng_xml).to be_equivalent_to Nokogiri::XML(mods)
      expect(Honeybadger).to have_received(:notify)
    end
  end
end
