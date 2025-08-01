# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe Workflow::StateBatchService do
  before do
    allow(QueueService).to receive(:enqueue)
  end

  describe '.accessioning_druids' do
    subject(:accessioning_druids) do
      described_class.accessioning_druids(druids: [accessioning_druid, missing_druid, accessioned_druid,
                                                   accessioning_druid_with_ignored_step])
    end

    let(:accessioned_druid) { 'druid:bb033gt0615' }
    let(:accessioning_druid) { 'druid:bb033gt0616' }
    let(:missing_druid) { 'druid:bb033gt0617' }
    let(:accessioning_druid_with_ignored_step) { 'druid:bb033gt0618' }

    before do
      # accessioned
      Workflow::Service.create(druid: accessioned_druid, workflow_name: 'accessionWF', version: 1)
      WorkflowStep.where(druid: accessioned_druid, active_version: true,
                         workflow: 'accessionWF').update_all(status: 'completed')
      # accessioning (with some steps completed)
      Workflow::Service.create(druid: accessioning_druid, workflow_name: 'accessionWF', version: 1)
      WorkflowStep.where(druid: accessioning_druid, active_version: true,
                         workflow: 'accessionWF').order(:id).limit(4).update_all(status: 'completed')
      # accessioning with all completed except the last step
      Workflow::Service.create(druid: accessioning_druid_with_ignored_step, workflow_name: 'accessionWF', version: 1)
      WorkflowStep.where(druid: accessioning_druid_with_ignored_step, active_version: true,
                         workflow: 'accessionWF').where.not(process: 'end-accession').update_all(status: 'completed')
    end

    it 'returns the accessioning druids' do
      expect(accessioning_druids).to contain_exactly(accessioning_druid)
    end
  end

  describe '.accessioned_druids' do
    subject(:accessioned_druids) do
      described_class.accessioned_druids(druids: [accessioned_druid, missing_druid, accessioning_druid])
    end

    let(:accessioned_druid) { 'druid:bb033gt0615' }
    let(:accessioning_druid) { 'druid:bb033gt0616' }
    let(:missing_druid) { 'druid:bb033gt0617' }

    before do
      create(:workflow_step, druid: accessioned_druid, workflow: 'accessionWF', active_version: true,
                             process: 'end-accession', lifecycle: 'accessioned', status: 'completed')
      create(:workflow_step, druid: accessioning_druid, workflow: 'accessionWF', active_version: true,
                             process: 'end-accession', lifecycle: 'accessioned', status: 'waiting')
    end

    it 'returns the accessioned druids' do
      expect(accessioned_druids).to contain_exactly(accessioned_druid)
    end
  end

  describe '.assembling_druids' do
    subject(:assembling_druids) do
      described_class.assembling_druids(
        druids: [
          assembling_druid, missing_druid, assembled_druid, assembling_druid_with_ignored_step,
          was_crawl_preassembling_druid, was_crawl_preassembled_druid, was_crawl_preassembling_druid_with_ignored_step,
          was_seed_preassembling_druid, was_seed_preassembled_druid, was_seed_preassembling_druid_with_ignored_step,
          gis_delivering_druid, gis_delivered_druid, gis_delivering_druid_with_ignored_step,
          ocring_druid, ocred_druid, ocring_druid_with_ignored_step,
          stting_druid, stted_druid, stting_druid_with_ignored_step,
          gis_assembling_druid, gis_assembled_druid
        ]
      )
    end

    let(:missing_druid) { 'druid:bb033gt0615' }
    let(:assembling_druid) { 'druid:bc033gt0615' }
    let(:assembled_druid) { 'druid:bc033gt0616' }
    let(:assembling_druid_with_ignored_step) { 'druid:bc033gt0617' }
    let(:was_crawl_preassembling_druid) { 'druid:bd033gt0615' }
    let(:was_crawl_preassembled_druid) { 'druid:bd033gt0616' }
    let(:was_crawl_preassembling_druid_with_ignored_step) { 'druid:bd033gt0617' }
    let(:was_seed_preassembling_druid) { 'druid:bf033gt0615' }
    let(:was_seed_preassembled_druid) { 'druid:bf033gt0616' }
    let(:was_seed_preassembling_druid_with_ignored_step) { 'druid:bf033gt0617' }
    let(:gis_delivering_druid) { 'druid:bg033gt0615' }
    let(:gis_delivered_druid) { 'druid:bg033gt0616' }
    let(:gis_delivering_druid_with_ignored_step) { 'druid:bg033gt0617' }
    let(:ocring_druid) { 'druid:bh033gt0615' }
    let(:ocred_druid) { 'druid:bh033gt0616' }
    let(:ocring_druid_with_ignored_step) { 'druid:bh033gt0617' }
    let(:stting_druid) { 'druid:bj033gt0615' }
    let(:stted_druid) { 'druid:bj033gt0616' }
    let(:stting_druid_with_ignored_step) { 'druid:bj033gt0617' }
    let(:gis_assembling_druid) { 'druid:bk033gt0615' }
    let(:gis_assembled_druid) { 'druid:bk033gt0616' }

    before do
      # assembling
      Workflow::Service.create(druid: assembling_druid, workflow_name: 'assemblyWF', version: 1)
      WorkflowStep.where(druid: assembling_druid, active_version: true,
                         workflow: 'assemblyWF').order(:id).limit(4).update_all(status: 'completed')
      # assembled
      Workflow::Service.create(druid: assembled_druid, workflow_name: 'assemblyWF', version: 1)
      WorkflowStep.where(druid: assembled_druid, active_version: true,
                         workflow: 'assemblyWF').update_all(status: 'completed')
      # assembling with all completed except the last step
      Workflow::Service.create(druid: assembling_druid_with_ignored_step, workflow_name: 'assemblyWF', version: 1)
      WorkflowStep.where(druid: assembling_druid_with_ignored_step, active_version: true,
                         workflow: 'assemblyWF').where.not(process: 'accessioning-initiate')
                  .update_all(status: 'completed')

      # wasCrawlPreassemblyWF assembling
      Workflow::Service.create(druid: was_crawl_preassembling_druid, workflow_name: 'wasCrawlPreassemblyWF', version: 1)
      # wasCrawlPreassemblyWF assembled
      Workflow::Service.create(druid: was_crawl_preassembled_druid, workflow_name: 'wasCrawlPreassemblyWF', version: 1)
      WorkflowStep.where(druid: was_crawl_preassembled_druid, active_version: true,
                         workflow: 'wasCrawlPreassemblyWF').update_all(status: 'completed')
      # wasCrawlPreassemblyWF assembling with all completed except the last step
      Workflow::Service.create(druid: was_crawl_preassembling_druid_with_ignored_step,
                               workflow_name: 'wasCrawlPreassemblyWF', version: 1)
      WorkflowStep.where(druid: was_crawl_preassembling_druid_with_ignored_step, active_version: true,
                         workflow: 'wasCrawlPreassemblyWF').where.not(process: 'end-was-crawl-preassembly')
                  .update_all(status: 'completed')

      # wasSeedPreassemblyWF assembling
      Workflow::Service.create(druid: was_seed_preassembling_druid, workflow_name: 'wasSeedPreassemblyWF', version: 1)
      # wasSeedPreassemblyWF assembled
      Workflow::Service.create(druid: was_seed_preassembled_druid, workflow_name: 'wasSeedPreassemblyWF', version: 1)
      WorkflowStep.where(druid: was_seed_preassembled_druid, active_version: true,
                         workflow: 'wasSeedPreassemblyWF').update_all(status: 'completed')
      # wasSeedPreassemblyWF assembling with all completed except the last step
      Workflow::Service.create(druid: was_seed_preassembling_druid_with_ignored_step,
                               workflow_name: 'wasSeedPreassemblyWF', version: 1)
      WorkflowStep.where(druid: was_seed_preassembling_druid_with_ignored_step, active_version: true,
                         workflow: 'wasSeedPreassemblyWF').where.not(process: 'end-was-seed-preassembly')
                  .update_all(status: 'completed')

      # gisDeliveryWF delivering
      Workflow::Service.create(druid: gis_delivering_druid, workflow_name: 'gisDeliveryWF', version: 1)
      WorkflowStep.where(druid: gis_delivering_druid, active_version: true,
                         workflow: 'gisDeliveryWF').order(:id).limit(2).update_all(status: 'completed')
      # gisDeliveryWF delivered
      Workflow::Service.create(druid: gis_delivered_druid, workflow_name: 'gisDeliveryWF', version: 1)
      WorkflowStep.where(druid: gis_delivered_druid, active_version: true,
                         workflow: 'gisDeliveryWF').update_all(status: 'completed')
      # gisDeliveryWF delivering with all completed except the last step
      Workflow::Service.create(druid: gis_delivering_druid_with_ignored_step, workflow_name: 'gisDeliveryWF',
                               version: 1)
      WorkflowStep.where(druid: gis_delivering_druid_with_ignored_step, active_version: true,
                         workflow: 'gisDeliveryWF').where.not(process: 'start-accession-workflow')
                  .update_all(status: 'completed')

      # ocrWF ocring
      Workflow::Service.create(druid: ocring_druid, workflow_name: 'ocrWF', version: 1)
      WorkflowStep.where(druid: ocring_druid, active_version: true,
                         workflow: 'ocrWF').order(:id).limit(2).update_all(status: 'completed')
      # ocrWF ocred
      Workflow::Service.create(druid: ocred_druid, workflow_name: 'ocrWF', version: 1)
      WorkflowStep.where(druid: ocred_druid, active_version: true,
                         workflow: 'ocrWF').update_all(status: 'completed')
      # ocrWF ocring with all completed except the last step
      Workflow::Service.create(druid: ocring_druid_with_ignored_step, workflow_name: 'ocrWF', version: 1)
      WorkflowStep.where(druid: ocring_druid_with_ignored_step, active_version: true,
                         workflow: 'ocrWF').where.not(process: 'end-ocr')
                  .update_all(status: 'completed')

      # speechToTextWF stting
      Workflow::Service.create(druid: stting_druid, workflow_name: 'speechToTextWF', version: 1)
      WorkflowStep.where(druid: stting_druid, active_version: true,
                         workflow: 'speechToTextWF').order(:id).limit(2).update_all(status: 'completed')
      # speechToTextWF stted
      Workflow::Service.create(druid: stted_druid, workflow_name: 'speechToTextWF', version: 1)
      WorkflowStep.where(druid: stted_druid, active_version: true,
                         workflow: 'speechToTextWF').update_all(status: 'completed')
      # speechToTextWF stting with all completed except the last step
      Workflow::Service.create(druid: stting_druid_with_ignored_step, workflow_name: 'speechToTextWF', version: 1)
      WorkflowStep.where(druid: stting_druid_with_ignored_step, active_version: true,
                         workflow: 'speechToTextWF').where.not(process: 'end-stt')
                  .update_all(status: 'completed')

      # gisAssemblyWF assembling
      Workflow::Service.create(druid: gis_assembling_druid, workflow_name: 'gisAssemblyWF', version: 1)
      WorkflowStep.where(druid: gis_assembling_druid, active_version: true,
                         workflow: 'gisAssemblyWF').order(:id).limit(4).update_all(status: 'completed')
      # gisAssemblyWF assembled
      Workflow::Service.create(druid: gis_assembled_druid, workflow_name: 'gisAssemblyWF', version: 1)
      WorkflowStep.where(druid: gis_assembled_druid, active_version: true,
                         workflow: 'gisAssemblyWF').update_all(status: 'completed')
    end

    it 'returns the assembling druids' do
      expect(assembling_druids).to contain_exactly(assembling_druid, was_crawl_preassembling_druid,
                                                   was_seed_preassembling_druid, gis_delivering_druid,
                                                   ocring_druid, stting_druid, gis_assembling_druid)
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
