# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:crawl?) { true }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(WorkflowService).to receive(:workflow?).and_return(crawl?)
    allow(WasShelvingService).to receive(:shelve)
    allow(EventFactory).to receive(:create)
  end

  context 'when the object is not a DRO' do
    let(:object) { build(:admin_policy, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(WasShelvingService).not_to have_received(:shelve)
      expect(EventFactory).not_to have_received(:create)
    end
  end

  context 'when the object is not a WAS Crawl' do
    let(:crawl?) { false }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(WasShelvingService).not_to have_received(:shelve)
      expect(EventFactory).not_to have_received(:create)
    end
  end

  context 'when the object is a WAS Crawl' do
    it 'shelves the object' do
      expect(perform).to be_nil # no return state defaults to completed.
      expect(WasShelvingService).to have_received(:shelve).with(object)
      expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'shelving_complete', data: {})
    end
  end
end
