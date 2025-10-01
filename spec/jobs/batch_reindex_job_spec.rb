# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchReindexJob do
  subject(:perform) do
    described_class.perform_now([druid, 'druid:bc123cd4567'])
  end

  let(:repository_object) { create(:repository_object, :with_repository_object_version) }
  let(:druid) { repository_object.external_identifier }

  let(:conn) { instance_double(RSolr::Client, add: nil) }
  let(:indexer) { double(Indexing::Indexers::CompositeIndexer, to_solr: solr_doc) } # rubocop:disable RSpec/VerifiedDoubles
  let(:solr_doc) { { id: repository_object.external_identifier } }
  let!(:release_tag) { create(:release_tag, druid:) }

  before do
    allow(RSolr).to receive(:connect).and_return(conn)
    allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    create(:workflow_step, druid:, lifecycle: 'accessioned', status: 'completed')
  end

  it 'indexes' do
    perform
    expect(conn).to have_received(:add).with([solr_doc], add_attributes: { commitWithin: 500 })
    expect(Indexing::Builders::DocumentBuilder).to have_received(:for).once.with(
      model: repository_object.head_version.to_cocina_with_metadata,
      trace_id: String,
      workflows: [an_instance_of(Workflow::WorkflowResponse)],
      release_tags: [release_tag.to_cocina]
    )
  end
end
