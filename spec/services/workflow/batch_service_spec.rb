# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::BatchService do
  let(:druid1) { 'druid:bb033gt0615' }
  let(:druid2) { 'druid:bc033gt0616' }

  describe '#workflows' do
    subject(:workflows) { described_class.workflows(druids: [druid1, druid2]) }

    let(:xml1) do
      <<~XML
        <?xml version="1.0"?>
        <workflow id="accessionWF" objectId="druid:bb033gt0615">
          <process version="1" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
        </workflow>
      XML
    end

    let(:xml2) do
      <<~XML
        <?xml version="1.0"?>
        <workflow id="accessionWF" objectId="druid:bc033gt0616">
          <process version="2" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
          <process version="1" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
        </workflow>
      XML
    end

    before do
      create(:workflow_step, :with_ocr_context, druid: druid1, updated_at: '2025-07-22T21:35:36+00:00',
                                                status: 'waiting')
      create(:workflow_step, :with_ocr_context, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00', version: 2)
      create(:workflow_step, :with_ocr_context, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00',
                                                status: 'waiting')
      create(:workflow_step, druid: druid2, updated_at: '2025-07-22T21:35:36+00:00', process: 'start',
                             workflow: 'wasCrawlPreassemblyWF')
    end

    it 'returns workflows' do
      expect(workflows).to be_a(Hash)
      expect(workflows.size).to eq 2
      expect(workflows[druid1].size).to eq 1
      expect(workflows[druid1].first).to be_a(Dor::Services::Response::Workflow)
      expect(workflows[druid1].first.xml).to be_equivalent_to xml1
      expect(workflows[druid2].size).to eq 2
      expect(workflows[druid2].first).to be_a(Dor::Services::Response::Workflow)
      expect(workflows[druid2].first.xml).to be_equivalent_to xml2
      # expect(workflows).to be_a(Array)
      # expect(workflows.first).to be_a(Dor::Services::Response::Workflow)
      # expect(workflows.first.xml).to be_equivalent_to xml
    end
  end
end
