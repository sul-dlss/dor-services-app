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
  end

  context 'with no errors' do
    before do
      allow(ResetWorkspaceService).to receive(:reset)
    end

    it 'invokes the ResetService and logs success' do
      perform
      expect(result).to have_received(:processing!).once
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
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

  context 'when an error' do
    before do
      allow(ResetWorkspaceService).to receive(:reset).and_raise('Grrrr')
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'logs failure' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace',
              output: { errors: [{ detail: 'Grrrr', title: 'Unable to reset workspace' }] })
    end
  end
end
