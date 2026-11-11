# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::WorkflowProcessIndexer do
  let(:solr_doc) { Indexing::WorkflowSolrDocument.new { |doc| doc.name = 'assemblyWF' } }
  let(:process) do
    instance_double(Workflow::ProcessResponse, status:, name: 'jp2-create', datetime: '2026-11-09T10:00:00Z',
                                               error_message: nil)
  end

  before do
    described_class.new(solr_doc:, workflow_name: 'assemblyWF', process:).to_solr
  end

  context 'when the process is in error' do
    let(:status) { 'error' }

    it 'records the error time' do
      expect(solr_doc.to_h['wf_error_latest_dtpsidv']).to eq '2026-11-09T10:00:00Z'
    end
  end

  %w[completed skipped waiting].each do |not_error_status|
    context "when the process is #{not_error_status}" do
      let(:status) { not_error_status }

      it 'does not record an error time' do
        expect(solr_doc.to_h).not_to have_key('wf_error_latest_dtpsidv')
      end
    end
  end
end
