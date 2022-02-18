# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ObjectCreator do
  subject(:result) { described_class.create(request, druid: druid, persister: persister, assign_doi: assign_doi) }

  let(:apo) { 'druid:bz845pv2292' }
  let(:minimal_cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: '0.0.1',
                                      externalIdentifier: 'druid:bz845pv2292',
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: { hasAdminPolicy: 'druid:hy787xj5878',
                                                        hasAgreement: 'druid:bb033gt0615' }
                                    })
  end
  let(:persister) { class_double(Cocina::ActiveFedoraPersister, store: nil) }
  let(:request) { Cocina::Models.build_request(params) }
  let(:druid) { 'druid:mb046vj7485' }
  let(:assign_doi) { false }

  before do
    allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    allow(Dor).to receive(:find).with(apo).and_return(Dor::AdminPolicyObject.new)
    allow(CocinaObjectStore).to receive(:find).with('druid:bz845pv2292').and_return(minimal_cocina_admin_policy)
    allow(RefreshMetadataAction).to receive(:run) do |args|
      args[:fedora_object].descMetadata.mods_title = 'foo'
    end
    allow(SynchronousIndexer).to receive(:reindex_remotely)
    allow(Settings.datacite).to receive(:prefix).and_return('10.25740')
  end

  context 'when Cocina::Models::RequestDRO is received' do
    context 'when no description is supplied but there is a identification.catalogLink' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/media.jsonld',
          'label' => ':auto',
          'access' => {},
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
          'access' => {},
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
          'access' => {},
          'version' => 1,
          'structural' => {},
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'donot:care'
          },
          description: {
            note: [
              {
                type: 'abstract',
                value: 'I am an abstract'
              },
              {
                type: 'email',
                value: 'marypoppins@umbrellas.org',
                displayLabel: 'Contact'
              },
              {
                type: 'preferred citation',
                value: 'Zappa, F. (2013) :link:'
              }
            ],
            title: [
              {
                value: 'more desc mappings'
              }
            ],
            subject: [
              {
                type: 'topic',
                value: 'I am a keyword'
              }
            ],
            contributor: [
              {
                name: [
                  {
                    value: 'Miss Piggy'
                  }
                ],
                role: [
                  {
                    value: 'Creator'
                  }
                ],
                type: 'person'
              },
              {
                name: [
                  {
                    value: 'funder.example.org'
                  }
                ],
                role: [
                  {
                    value: 'Funder'
                  }
                ],
                type: 'organization'
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

      it 'abstract (note of type abstract) is set' do
        summary_note = result.description.note.find { |note| note.type == 'abstract' }
        expect(summary_note.value).to eq 'I am an abstract'
      end

      it 'contact (note of type contact) is set' do
        contact_note = result.description.note.find { |note| note.type == 'email' }
        expect(contact_note.value).to eq 'marypoppins@umbrellas.org'
        expect(contact_note.displayLabel).to eq 'Contact'
      end

      it 'preferred citation is set with the link placeholder replaced' do
        contact_note = result.description.note.find { |note| note.type == 'preferred citation' }
        expect(contact_note.value).to eq 'Zappa, F. (2013) https://purl.stanford.edu/mb046vj7485'
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

    context 'when the type is agreement' do
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/agreement.jsonld',
          'label' => 'My Agreement',
          'access' => {},
          'version' => 1,
          'administrative' => {
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'identifier:1'
          }
        }
      end

      it 'creates an agreement' do
        expect(result.type).to eq Cocina::Models::Vocab.agreement
      end
    end

    context 'when assigning DOI' do
      let(:assign_doi) { true }

      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
          'label' => ':auto',
          'access' => {},
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

      it 'adds DOI' do
        expect(result.identification.doi).to eq '10.25740/mb046vj7485'
      end
    end

    context 'when retaining DOI for trial' do
      subject(:result) { described_class.trial_create(request, cocina_object_store: nil, notifier: nil) }

      let(:request) { Cocina::Models.build(params) }
      let(:params) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
          'label' => ':auto',
          'externalIdentifier' => 'druid:bb010dx6027',
          'access' => {},
          'version' => 1,
          'structural' => {},
          'administrative' => {
            'partOfProject' => 'Naxos : 2009',
            'hasAdminPolicy' => apo
          },
          'identification' => {
            'sourceId' => 'sul:8.559351',
            'catalogLinks' => [{ 'catalog' => 'symphony', 'catalogRecordId' => '10121797' }],
            'doi' => '10.25740/bb010dx6027'
          }
        }
      end

      it 'keeps DOI' do
        expect(result[1].identification.doi).to eq '10.25740/bb010dx6027'
      end
    end
  end

  context 'when postgres create is enabled' do
    let(:params) do
      {
        'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
        'label' => 'label value',
        'access' => {},
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

    let(:cocina_object_store) { instance_double(CocinaObjectStore, cocina_to_ar_save: nil) }

    before do
      allow(Settings.enabled_features.postgres).to receive(:create).and_return(true)
      allow(CocinaObjectStore).to receive(:new).and_return(cocina_object_store)
    end

    it 'saves to postgres' do
      result

      expect(cocina_object_store).to have_received(:cocina_to_ar_save).with(instance_of(Cocina::Models::DRO))
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
          'access' => {},
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
                'type' => 'abstract'
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

      it 'collection abstract (note of type abstract) is set' do
        summary_note = result.description.note.find { |note| note.type == 'abstract' }
        expect(summary_note.value).to eq 'I am an abstract'
      end
    end
  end

  context 'when geographic is supplied' do
    let(:geo_xml) { '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>' }

    let(:params) do
      {
        'type' => Cocina::Models::Vocab.geo,
        'label' => ':auto',
        'access' => {},
        'version' => 1,
        'structural' => {},
        'administrative' => {
          'hasAdminPolicy' => apo
        },
        'identification' => {
          'sourceId' => 'sul:8.559351'
        },
        description: {
          title: [
            {
              value: 'a map'
            }
          ]
        },
        'geographic' => {
          'iso19139' => geo_xml
        }
      }
    end

    it 'geoMetadata content is set' do
      expect(result.geographic.iso19139).to eq geo_xml
    end
  end
end
