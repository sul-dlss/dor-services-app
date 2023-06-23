# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetWorkspaceJob do
  subject(:perform) do
    described_class.perform_now(druid:, version:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:version) { 1 }

  context 'with no errors' do
    before do
      allow(ResetWorkspaceService).to receive(:reset)
    end

    it 'invokes the ResetService' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
    end
  end

  context 'with ResetWorkspaceService::DirectoryAlreadyExists' do
    before do
      allow(ResetWorkspaceService).to receive(:reset).and_raise(ResetWorkspaceService::DirectoryAlreadyExists)
    end

    it 'ignores' do
      perform
      expect(ResetWorkspaceService).to have_received(:reset).with(druid:, version:).once
    end
  end
end
