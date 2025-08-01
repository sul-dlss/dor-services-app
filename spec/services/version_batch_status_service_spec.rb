# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionBatchStatusService do
  describe '.call' do
    subject(:statuses) { described_class.call(druids: [open_druid, accessioning_druid, missing_druid]) }

    let(:open_druid) { 'druid:mx123qw2323' }
    let(:accessioning_druid) { 'druid:fp165nz4391' }
    let(:missing_druid) { 'druid:bm077td6448' }

    before do
      create(:repository_object_version, :with_repository_object, external_identifier: open_druid, version: 1)
      # This object does not have any assembly workflows

      accessioning_repository_object_version = create(:repository_object_version, :with_repository_object,
                                                      external_identifier: accessioning_druid, version: 2)
      accessioning_repository_object_version.repository_object.close_version!(description: 'Best version ever')
      # This object has an assembly workflow that is sufficiently completed.
      allow(QueueService).to receive(:enqueue)
      Workflow::Service.create(druid: accessioning_druid, workflow_name: 'assemblyWF', version: 2)
      steps = WorkflowStep.where(druid: accessioning_druid, active_version: true,
                                 workflow: 'assemblyWF').order(:id).to_a
      steps.pop # Skip the last step.
      steps.each { |step| step.update(status: 'completed') }
      # This object has a completed accessioning workflow.
      Workflow::Service.create(druid: accessioning_druid, workflow_name: 'accessionWF', version: 1)
      steps = WorkflowStep.where(druid: accessioning_druid, active_version: true, workflow: 'accessionWF')
      steps.each { |step| step.update(status: 'completed', active_version: false) }

      # This object has an active accessioning workflow that is in progress.
      Workflow::Service.create(druid: accessioning_druid, workflow_name: 'accessionWF', version: 2)
      step = WorkflowStep.where(druid: accessioning_druid, active_version: true, workflow: 'accessionWF').first
      step.update!(status: 'started')
    end

    it 'returns the version status for the provided druids' do
      expect { statuses }.to make_database_queries(count: 4)
      expect(statuses).to match('druid:mx123qw2323' => {
                                  versionId: 1,
                                  open: true,
                                  openable: false,
                                  assembling: false,
                                  accessioning: false,
                                  closeable: true,
                                  discardable: false,
                                  versionDescription: 'Best version ever'
                                },
                                'druid:fp165nz4391' => {
                                  versionId: 2,
                                  open: false,
                                  openable: false,
                                  assembling: false,
                                  accessioning: true,
                                  closeable: false,
                                  discardable: false,
                                  versionDescription: 'Best version ever'
                                })
    end
  end

  describe '.call_single' do
    context 'when the object is found' do
      subject(:status) { described_class.call_single(druid:) }

      let(:druid) { 'druid:mx123qw2323' }

      before do
        create(:repository_object_version, :with_repository_object, external_identifier: druid, version: 1)
      end

      it 'returns the version status for the provided druids' do
        expect { status }.to make_database_queries(count: 4)
        expect(status).to match({
                                  versionId: 1,
                                  open: true,
                                  openable: false,
                                  assembling: false,
                                  accessioning: false,
                                  closeable: true,
                                  discardable: false,
                                  versionDescription: 'Best version ever'
                                })
      end
    end

    context 'when the object is not found' do
      subject(:status) { described_class.call_single(druid:) }

      let(:druid) { 'druid:bm077td6448' }

      it 'raises an error' do
        expect { status }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError, 'Object not found')
      end
    end
  end
end
