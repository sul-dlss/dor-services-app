# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishItemsModifiedJob do
  subject(:perform) do
    described_class.perform_now(collection_identifier)
  end

  let(:collection_identifier) { 'druid:mk420bs7601' }

  before do
    allow(MemberService).to receive(:for).and_return([{ 'id' => '123' }, { 'id' => '456' }])
    allow(CocinaObjectStore).to receive(:find).and_return(instance_double(Cocina::Models::DRO), instance_double(Cocina::Models::DRO))
    allow(Indexer).to receive(:reindex_later)
    perform
  end

  it 'sends object updated notifications for each member' do
    expect(Indexer).to have_received(:reindex_later).twice
  end
end
