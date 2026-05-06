# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::TemplateService do
  describe '.template' do
    context 'when the template exists' do
      let(:template) { described_class.template(workflow_name: 'assemblyWF') }

      it 'returns a workflow template' do
        expect(template['processes']).to eq [
          { 'label' => 'Initiate assembly of the object',
            'name' => 'start-assembly' },
          { 'label' =>
            'Create structural metadata from stub (from Goobi) if it exists.',
            'name' => 'content-metadata-create' },
          { 'label' => 'Create JP2 derivatives for images in object',
            'name' => 'jp2-create' },
          { 'label' => 'Compute and compare checksums for any files referenced in cocina',
            'name' => 'checksum-compute' },
          { 'label' => 'Calculate and add exif, mimetype, file size and other attributes to each file in cocina',
            'name' => 'exif-collect' },
          { 'label' => 'Initiate workspace and start common accessioning',
            'name' => 'accessioning-initiate' }
        ]
      end
    end

    context 'when the template does not exist' do
      it 'raises' do
        expect { described_class.template(workflow_name: 'non_existent') }
          .to raise_error(Workflow::Service::NotFoundException, "Workflow template 'non_existent' not found")
      end
    end
  end

  describe '.templates' do
    it 'returns a list of workflow template names' do
      expect(described_class.templates).to eq(
        %w[
          accessionWF
          assemblyWF
          captionWF
          digitizationWF
          gisAssemblyWF
          gisDeliveryWF
          goobiWF
          ocrWF
          preservationAuditWF
          preservationIngestWF
          releaseWF
          sdrIngestWF
          sdrRecoveryWF
          speechToTextWF
          wasCrawlDisseminationWF
          wasCrawlPreassemblyWF
          wasDisseminationWF
          wasSeedDisseminationWF
          wasSeedPreassemblyWF
        ]
      )
    end
  end
end
