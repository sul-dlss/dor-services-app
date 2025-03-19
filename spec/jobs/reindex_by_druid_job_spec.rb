# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexByDruidJob do
  let(:message) { { druid: }.to_json }
  let(:druid) { 'druid:bc123df4567' }

  before do
    allow(Indexer).to receive(:reindex_later)
  end

  it 'invokes the Indexer' do
    described_class.new.work(message)
    expect(Indexer).to have_received(:reindex_later).with(druid:)
  end
end
