# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ObjectCreator do
  subject(:item) { described_class.create(request, persister: persister) }

  let(:apo) { 'druid:bz845pv2292' }
  let(:persister) { class_double(Cocina::ActiveFedoraPersister, store: nil) }

  before do
    allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    allow(Dor).to receive(:find).with(apo).and_return(Dor::AdminPolicyObject.new)
    allow(Dor::SuriService).to receive(:mint_id).and_return('druid:mb046vj7485')
    allow(RefreshMetadataAction).to receive(:run) do |args|
      args[:datastream].mods_title = 'foo'
    end
    allow(SynchronousIndexer).to receive(:reindex_remotely)
  end

  context 'when item is a Dor::Item' do
    let(:params) do
      {
        'type' => 'http://cocina.sul.stanford.edu/models/media.jsonld',
        'label' => ':auto',
        'access' => { 'access' => 'dark', 'download' => 'none' },
        'version' => 1, 'structural' => {},
        'administrative' => {
          'partOfProject' => 'Naxos : 2009',
          'hasAdminPolicy' => apo
        },
        'identification' => {
          'sourceId' => 'sul:8.559351',
          'catalogLinks' => [{ 'catalog' => 'symphony', 'catalogRecordId' => '10121797' }]
        }
      }
    end

    let(:request) { Cocina::Models.build_request(params) }

    context 'when the access is dark' do
      it 'creates dark access' do
        expect(item.access.access).to eq 'dark'
      end
    end
  end
end
