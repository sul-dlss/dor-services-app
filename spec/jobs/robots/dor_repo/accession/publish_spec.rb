# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::Publish, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Publish::MetadataTransferService).to receive(:publish)
    allow(EventFactory).to receive(:create)
  end

  context 'when the object is an admin policy' do
    let(:object) { build(:admin_policy, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'Admin policy objects are not published'
      expect(Publish::MetadataTransferService).not_to have_received(:publish)
      expect(EventFactory).not_to have_received(:create)
    end
  end

  context 'when the object is not an admin policy' do
    let(:object) { build(:dro, id: druid) }

    it 'publishes the object' do
      expect(perform).to be_nil # no return state defaults to completed.
      expect(Publish::MetadataTransferService).to have_received(:publish).with(druid: druid)
      expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'publishing_complete', data: {})
    end
  end
end
