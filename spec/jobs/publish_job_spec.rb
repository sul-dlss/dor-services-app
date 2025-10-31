# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob do
  subject(:perform) do
    described_class.perform_now(druid:, background_job_result: result, release:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Cocina::Models::DRO, admin_policy?: false, version: 2) }
  let(:valid) { true }
  let(:invalid_filenames) { [] }
  let(:release) { false }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(result).to receive(:complete!)
    allow(EventFactory).to receive(:create)
    allow(Publish::MetadataTransferService).to receive(:publish)
  end

  context 'with no errors' do
    before do
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the Publish::MetadataTransferService' do
      expect(Publish::MetadataTransferService).to have_received(:publish).with(druid:, user_version: nil).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)

      expect(result).to have_received(:complete!).once
    end
  end

  context 'when releasing' do
    let(:release) { true }

    before do
      allow(Workflow::Service).to receive(:create)
      perform
    end

    it 'starts a releaseWF' do
      expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'releaseWF',
                                                               version: 2)
    end
  end

  context 'when an AdminPolicy' do
    let(:item) { instance_double(Cocina::Models::AdminPolicy, admin_policy?: true) }

    before do
      allow(result).to receive(:output=)
      perform
    end

    it 'marks the job as a failure' do
      expect(result).to have_received(:output=).with({ errors: [{ title: 'Publishing error',
                                                                  detail: 'Cannot publish an admin policy' }] })
      expect(result).to have_received(:complete!).once
    end

    it 'does not transfer' do
      expect(Publish::MetadataTransferService).not_to have_received(:publish)
    end
  end
end
