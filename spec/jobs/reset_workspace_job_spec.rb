# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetWorkspaceJob do
  subject(:perform) do
    described_class.perform_now(druid:, version:, background_job_result: result, workflow:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:version) { 1 }
  let(:result) { create(:background_job_result) }
  let(:workflow) { 'accessionWF' }

  before do
    allow(result).to receive(:processing!)
    allow(LogSuccessJob).to receive(:perform_later)
    allow(ResetWorkspaceService).to receive(:reset)
    allow(CleanupService).to receive(:cleanup_by_druid)
  end

  context 'with no errors' do
    it 'invokes the ResetService and CleanupService and logs success' do
      perform
      expect(result).to have_received(:processing!).once
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid).once
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace')
    end
  end

  context 'with ResetWorkspaceService::DirectoryAlreadyExists' do
    before do
      allow(ResetWorkspaceService).to receive(:reset).and_raise(ResetWorkspaceService::DirectoryAlreadyExists)
    end

    it 'ignores and logs success' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace')
    end
  end

  context 'when an error in ResetWorkspaceService' do
    before do
      allow(ResetWorkspaceService).to receive(:reset).and_raise('Grrrr')
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'logs failure' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
      expect(CleanupService).not_to have_received(:cleanup_by_druid).with(druid)
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace',
              output: { errors: [{ detail: 'Grrrr', title: 'Unable to cleanup/reset workspace' }] })
    end
  end

  context 'when an error in CleanupService' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid).and_raise('Doh')
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'logs failure' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid).once
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace',
              output: { errors: [{ detail: 'Doh', title: 'Unable to cleanup/reset workspace' }] })
    end
  end
end
