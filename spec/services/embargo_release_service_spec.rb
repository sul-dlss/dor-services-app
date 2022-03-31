# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoReleaseService do
  let(:service) { described_class.new(druid) }

  let(:druid) { 'druid:bb033gt0615' }

  describe '#release' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 1) }

    let(:open_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 2) }

    let(:released_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 2) }

    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: accessioned?) }

    let(:accessioned?) { true }

    let(:can_open?) { true }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(VersionService).to receive(:can_open?).and_return(can_open?)
      allow(VersionService).to receive(:open).and_return(open_cocina_object)
      allow(VersionService).to receive(:close)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(service).to receive(:release_cocina_object).and_return(released_cocina_object)
      allow(Rails.logger).to receive(:warn)
      allow(Notifications::EmbargoLifted).to receive(:publish)
      allow(Rails.logger).to receive(:error)
      allow(Honeybadger).to receive(:notify)
      allow(EventFactory).to receive(:create)
    end

    context 'when not yet accessioned' do
      let(:accessioned?) { false }

      it 'skips' do
        service.release
        expect(Rails.logger).to have_received(:warn).with("Skipping #{druid} - not yet accessioned")
        expect(workflow_client).to have_received(:lifecycle).with(druid: druid, milestone_name: 'accessioned')
        expect(VersionService).not_to have_received(:can_open?)
      end
    end

    context 'when already open' do
      let(:can_open?) { false }

      it 'skips' do
        service.release
        expect(Rails.logger).to have_received(:warn).with("Skipping #{druid} - object is already open")
        expect(VersionService).to have_received(:can_open?).with(cocina_object)
        expect(VersionService).not_to have_received(:open)
      end
    end

    context 'when not open' do
      it 'lifts embargo' do
        service.release
        expect(VersionService).to have_received(:open).with(cocina_object, event_factory: EventFactory)
        expect(service).to have_received(:release_cocina_object).with(open_cocina_object)
        expect(VersionService).to have_received(:close).with(released_cocina_object, { description: 'embargo released', significance: 'admin' }, event_factory: EventFactory)
        expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'embargo_released', data: {})
        expect(Notifications::EmbargoLifted).to have_received(:publish).with(model: released_cocina_object)
      end
    end

    context 'when error raised' do
      before do
        allow(VersionService).to receive(:open).and_raise('Nope.')
      end

      it 'logs and notifies' do
        service.release
        expect(Rails.logger).to have_received(:error)
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end

  describe '#release_cocina_object' do
    let(:embargoed_cocina_object) do
      Cocina::Models::DRO.new({
                                cocinaVersion: '0.0.1',
                                externalIdentifier: druid,
                                type: Cocina::Models::ObjectType.book,
                                label: 'Test DRO',
                                description: {
                                  title: [{ value: 'Test DRO' }],
                                  purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                },
                                version: 1,
                                access: access,
                                structural: structural,
                                administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                identification: { sourceId: 'sul:123' }
                              })
    end

    let(:structural) do
      Cocina::Models::DROStructural.new(
        {
          contains: [
            {
              version: 1,
              type: Cocina::Models::FileSetType.file,
              label: 'Page 1',
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777/123-456-789',
              structural: { contains: [
                {
                  version: 1,
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777/123-456-789/00001.html',
                  filename: '00001.html',
                  label: '00001.html',
                  hasMimeType: 'text/html',
                  use: 'transcription',
                  administrative: {
                    publish: false,
                    sdrPreserve: true,
                    shelve: false
                  },
                  access: {
                    view: 'dark'
                  },
                  hasMessageDigests: [
                    {
                      type: 'sha1',
                      digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                    },
                    {
                      type: 'md5',
                      digest: 'e6d52da47a5ade91ae31227b978fb023'
                    }
                  ]
                }
              ] }
            }
          ]
        }
      ).to_h
    end

    before do
      # This allows getting back the cocina object that was saved.
      allow(CocinaObjectStore).to receive(:save) { |cocina_object| cocina_object }
    end

    context 'when embargo access is world' do
      let(:access) do
        Cocina::Models::DROAccess.new({
                                        view: 'citation-only',
                                        download: 'none',
                                        embargo: {
                                          releaseDate: DateTime.parse('2029-02-28'),
                                          view: 'world',
                                          download: 'world',
                                          useAndReproductionStatement: 'Free!'
                                        }
                                      }).to_h
      end

      it 'moves embargo to access and updates file access' do
        released_cocina_object = service.send(:release_cocina_object, embargoed_cocina_object)
        expect(released_cocina_object.access.to_h).to eq(
          {
            view: 'world',
            download: 'world',
            useAndReproductionStatement: 'Free!'
          }
        )
        expect(released_cocina_object.structural.contains.first.structural.contains.first.access.to_h).to eq(
          {
            view: 'world',
            download: 'world'
          }
        )
        expect(CocinaObjectStore).to have_received(:save)
      end
    end

    context 'when embargo access is citation-only' do
      let(:access) do
        Cocina::Models::DROAccess.new({
                                        view: 'citation-only',
                                        download: 'none',
                                        embargo: {
                                          releaseDate: DateTime.parse('2029-02-28'),
                                          view: 'citation-only',
                                          download: 'none',
                                          useAndReproductionStatement: 'Free!'
                                        }
                                      }).to_h
      end

      it 'moves embargo to access and updates file access' do
        released_cocina_object = service.send(:release_cocina_object, embargoed_cocina_object)
        expect(released_cocina_object.access.to_h).to eq(
          {
            view: 'citation-only',
            download: 'none',
            useAndReproductionStatement: 'Free!'
          }
        )
        expect(released_cocina_object.structural.contains.first.structural.contains.first.access.to_h).to eq(
          {
            view: 'dark',
            download: 'none'
          }
        )
        expect(CocinaObjectStore).to have_received(:save)
      end
    end

    context 'when structural is nil' do
      let(:embargoed_cocina_object) do
        Cocina::Models::DRO.new({
                                  cocinaVersion: '0.0.1',
                                  externalIdentifier: druid,
                                  type: Cocina::Models::ObjectType.book,
                                  label: 'Test DRO',
                                  version: 1,
                                  description: {
                                    title: [{ value: 'Test DRO' }],
                                    purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                  },
                                  access: access,
                                  administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                  structural: {},
                                  identification: { sourceId: 'sul:123' }
                                })
      end

      let(:access) do
        Cocina::Models::DROAccess.new({
                                        view: 'citation-only',
                                        download: 'none',
                                        embargo: {
                                          releaseDate: DateTime.parse('2029-02-28'),
                                          view: 'citation-only',
                                          download: 'none',
                                          useAndReproductionStatement: 'Free!'
                                        }
                                      }).to_h
      end

      it 'moves embargo to access' do
        released_cocina_object = service.send(:release_cocina_object, embargoed_cocina_object)
        expect(released_cocina_object.access.to_h).to eq(
          {
            view: 'citation-only',
            download: 'none',
            useAndReproductionStatement: 'Free!'
          }
        )
        expect(CocinaObjectStore).to have_received(:save)
      end
    end
  end

  describe '#release_all' do
    let(:response) do
      { 'response' => { 'numFound' => 1, 'docs' => [{ 'id' => 'druid:999' }] } }
    end

    before do
      allow(SolrService).to receive(:get).and_return(response)
      allow(described_class).to receive(:release)
    end

    it 'releases based on Solr query' do
      described_class.release_all
      expect(described_class).to have_received(:release).with('druid:999')
    end
  end
end
