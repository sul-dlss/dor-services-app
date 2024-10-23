# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupVersionJob do
  subject(:perform) do
    described_class.perform_now(druid:, version:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:version) { '2' }

  before do
    allow(EventFactory).to receive(:create)
    allow(CleanupService).to receive(:delete_accessioning_workflows)
  end

  context 'with no errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid)
    end

    it 'cleans up and records an event' do
      perform

      expect(CleanupService).to have_received(:delete_accessioning_workflows).with(druid, version)
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid)
      expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'cleanup-workspace', data: { status: 'success' })
    end
  end

  context 'with errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid).and_raise(Errno::ENOENT)
    end

    it 'records an event' do
      perform

      expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'cleanup-workspace', data: { status: 'failure', message: 'No such file or directory', backtrace: Array })
    end
  end
end
