# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ObjectCreator do
  subject(:result) { described_class.create(request, persister: persister) }

  let(:apo) { 'druid:bz845pv2292' }
  let(:persister) { class_double(Cocina::ActiveFedoraPersister, store: nil) }
  let(:request) { Cocina::Models.build_request(params) }

  before do
    allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    allow(Dor).to receive(:find).with(apo).and_return(Dor::AdminPolicyObject.new)
    allow(Dor::SuriService).to receive(:mint_id).and_return('druid:mb046vj7485')
    allow(RefreshMetadataAction).to receive(:run) do |args|
      args[:datastream].mods_title = 'foo'
    end
    allow(SynchronousIndexer).to receive(:reindex_remotely)
  end

  context 'when Cocina::Models::RequestDRO is received' do
    context 'when no description is supplied but there is a identification.catalogLink' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/media.jsonld',
          'label' => ':auto',
          'access' => { 'access' => 'world' },
          'version' => 1,
          'structural' => {},
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'sul:8.559351',
            'catalogLinks' => [{ 'catalog' => 'symphony', 'catalogRecordId' => '10121797' }]
          }
        }
      end

      it 'title is set to result of RefreshMetadataAction when there is a catalogLink' do
        expect(result.description.title.first.value).to eq 'foo'
      end
    end

    context 'when no description is supplied (no title, but label)' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
          'label' => 'label value',
          'access' => { 'access' => 'world' },
          'version' => 1,
          'structural' => {},
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'donot:care'
          }
        }
      end

      it 'title is set to label' do
        expect(result.description.title.first.value).to eq 'label value'
      end
    end

    context 'when description is supplied' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
          'label' => 'contributor mapping test',
          'access' => { 'access' => 'world' },
          'version' => 1,
          'structural' => {},
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'donot:care'
          },
          "description": {
            "note": [
              {
                "type": 'summary',
                "value": 'I am an abstract'
              },
              {
                "type": 'email',
                "value": 'marypoppins@umbrellas.org',
                "displayLabel": 'Contact'
              },
              {
                "type": 'preferred citation',
                "value": 'Zappa, F. (2013) :link:'
              }
            ],
            "title": [
              {
                "value": 'more desc mappings'
              }
            ],
            "subject": [
              {
                "type": 'topic',
                "value": 'I am a keyword'
              }
            ],
            "contributor": [
              {
                "name": [
                  {
                    "value": 'Miss Piggy'
                  }
                ],
                "role": [
                  {
                    "value": 'Creator'
                  }
                ],
                "type": 'person'
              },
              {
                "name": [
                  {
                    "value": 'funder.example.org'
                  }
                ],
                "role": [
                  {
                    "value": 'Funder'
                  }
                ],
                "type": 'organization'
              }
            ]
          }
        }
      end

      it 'title is set to value passed in' do
        expect(result.description.title.first.value).to eq 'more desc mappings'
      end

      it 'contributors are set' do
        expect(result.description.contributor.first.type).to eq 'person'
        expect(result.description.contributor.first.name.first.value).to eq 'Miss Piggy'
        expect(result.description.contributor.first.role.first.value).to eq 'Creator'
        expect(result.description.contributor.last.type).to eq 'organization'
        expect(result.description.contributor.last.name.first.value).to eq 'funder.example.org'
        expect(result.description.contributor.last.role.first.value).to eq 'Funder'
      end

      it 'subjects are set' do
        expect(result.description.subject.first.type).to eq 'topic'
        expect(result.description.subject.first.value).to eq 'I am a keyword'
      end

      it 'abstract (note of type summary) is set' do
        summary_note = result.description.note.find { |note| note.type == 'summary' }
        expect(summary_note.value).to eq 'I am an abstract'
      end

      it 'contact (note of type contact) is set' do
        contact_note = result.description.note.find { |note| note.type == 'email' }
        expect(contact_note.value).to eq 'marypoppins@umbrellas.org'
        expect(contact_note.displayLabel).to eq 'Contact'
      end

      it 'preferred citation is set with the link placeholder replaced' do
        contact_note = result.description.note.find { |note| note.type == 'preferred citation' }
        expect(contact_note.value).to eq 'Zappa, F. (2013) http://purl.stanford.edu/mb046vj7485'
      end
    end

    context 'when the access is dark' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/media.jsonld',
          'label' => ':auto',
          'access' => { 'access' => 'dark', 'download' => 'none' },
          'version' => 1,
          'structural' => {},
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

      it 'creates dark access' do
        expect(result.access.access).to eq 'dark'
      end
    end

    context "when the collection doesn't exist" do
      before do
        allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
      end

      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/media.jsonld',
          'label' => ':auto',
          'access' => { 'access' => 'world', 'download' => 'world' },
          'version' => 1,
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'structural' => {
            'isMemberOf' => ['druid:bk024qs1809']
          },
          'identification' => {
            'sourceId' => 'sul:8.559351',
            'catalogLinks' => [{ 'catalog' => 'symphony', 'catalogRecordId' => '10121797' }]
          }
        }
      end

      it 'raises an error' do
        expect { result }.to raise_error Cocina::ValidationError
      end
    end
  end

  context 'when Cocina::Models::RequestCollection is received' do
    let(:request) { Cocina::Models.build_request(params) }

    context 'when there is a note of type summary' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/collection.jsonld',
          'label' => 'collection label',
          'version' => 1,
          'access' => { 'access' => 'world' },
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'description' => {
            'title' => [
              {
                'value' => 'collection title'
              }
            ],
            'note' => [
              {
                # NOTE: current mappings require that this is the first note
                'value' => 'I am an abstract',
                'type' => 'summary'
              },
              {
                'value' => 'I am not an abstract',
                'type' => 'other'
              }
            ]
          }
        }
      end

      it 'collection title is set to params title' do
        expect(result.description.title.first.value).to eq 'collection title'
      end

      it 'collection abstract (note of type summary) is set' do
        summary_note = result.description.note.select { |note| note.type == 'summary' }.first
        expect(summary_note.value).to eq 'I am an abstract'
      end
    end
  end
end
