# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchReindexJob do
  subject(:perform) do
    described_class.perform_now([repository_object.external_identifier, 'druid:bc123cd4567'])
  end

  let(:repository_object) { create(:repository_object, :with_repository_object_version) }

  let(:conn) { instance_double(RSolr::Client, add: nil) }
  let(:indexer) { double(Indexing::Indexers::CompositeIndexer, to_solr: solr_doc) } # rubocop:disable RSpec/VerifiedDoubles
  let(:solr_doc) { { id: repository_object.external_identifier } }

  before do
    allow(RSolr).to receive(:connect).and_return(conn)
    allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
  end

  it 'indexes' do
    perform
    expect(conn).to have_received(:add).with([solr_doc], add_attributes: { commitWithin: 500 })
    expect(Indexing::Builders::DocumentBuilder).to have_received(:for).once.with(
      model: repository_object.head_version.to_cocina_with_metadata,
      trace_id: String
    )
  end
end
