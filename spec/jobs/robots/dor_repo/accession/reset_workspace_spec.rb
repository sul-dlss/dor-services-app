# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::ResetWorkspace, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  before do
    allow(EventFactory).to receive(:create)
  end

  context 'with no errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid)
    end

    it 'performs cleanup' do
      expect(perform).to be_nil # no return state defaults to completed.
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid).once
      expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'cleanup-workspace',
                                                          data: { status: 'success' })
    end
  end

  context 'with errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid).and_raise(Errno::ENOENT)
    end

    it 'raises' do
      expect { perform }.to raise_error(Errno::ENOENT)
      expect(EventFactory).to have_received(:create)
        .with(druid:, event_type: 'cleanup-workspace', data: { status: 'failure',
                                                               message: 'No such file or directory' })
    end
  end
end
