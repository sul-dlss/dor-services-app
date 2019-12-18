# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshMetadataAction do
  subject(:refresh) { described_class.run(identifiers: ['catkey:123'], datastream: item.descMetadata) }

  let(:item) { Dor::Item.new }

  before do
    allow(MetadataService).to receive(:fetch).and_return('<xml/>')
  end

  it 'gets the data and puts it in descMetadata' do
    expect(refresh).not_to be_nil
    expect(item.descMetadata.content).to eq '<xml/>'
  end
end
