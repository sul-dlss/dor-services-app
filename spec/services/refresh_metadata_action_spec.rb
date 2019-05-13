# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshMetadataAction do
  subject(:refresh) { described_class.run(item) }

  let(:item) { Dor::Item.new }

  before do
    allow(item.identityMetadata).to receive(:otherId).and_return(['catkey:123'])
    allow(MetadataService).to receive(:fetch).and_return('<xml/>')
  end

  it 'gets the data an puts it in descMetadata' do
    expect(refresh).not_to be_nil
    expect(item.descMetadata.content).to eq '<xml/>'
  end
end
