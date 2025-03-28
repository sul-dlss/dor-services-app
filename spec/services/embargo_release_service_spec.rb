# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoReleaseService do
  let(:service) { described_class.new(druid) }

  let(:druid) { 'druid:bb033gt0615' }

  describe '#release' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 1) }

    let(:open_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 2) }

    let(:released_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 3) }

    let(:accessioned?) { true }

    let(:can_open?) { true }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
      allow(VersionService).to receive_messages(can_open?: can_open?, open: open_cocina_object)
      allow(VersionService).to receive(:close)
      allow(WorkflowStateService).to receive(:accessioned?).and_return(accessioned?)
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
        expect(WorkflowStateService).to have_received(:accessioned?).with(druid:, version: 1)
        expect(VersionService).not_to have_received(:can_open?)
      end
    end

    context 'when already open' do
      let(:can_open?) { false }

      it 'skips' do
        service.release
        expect(VersionService).to have_received(:can_open?).with(druid:, version: 1)
        expect(VersionService).not_to have_received(:open)
      end
    end

    context 'when not open' do
      it 'lifts embargo' do
        service.release
        expect(VersionService).to have_received(:open).with(cocina_object:, description: 'embargo released')
        expect(service).to have_received(:release_cocina_object).with(open_cocina_object)
        expect(VersionService).to have_received(:close).with(druid:, version: 3)
        expect(EventFactory).to have_received(:create).with(druid:, event_type: 'embargo_released', data: {})
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
      build(:dro).new(access:, structural:)
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
      allow(UpdateObjectService).to receive(:update) { |cocina_object| cocina_object }
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
          Cocina::Models::DROAccess.new(
            view: 'world',
            download: 'world',
            useAndReproductionStatement: 'Free!'
          ).to_h
        )
        expect(released_cocina_object.structural.contains.first.structural.contains.first.access.to_h).to eq(
          Cocina::Models::FileAccess.new(
            view: 'world',
            download: 'world'
          ).to_h
        )
        expect(UpdateObjectService).to have_received(:update)
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
          Cocina::Models::DROAccess.new(
            view: 'citation-only',
            download: 'none',
            useAndReproductionStatement: 'Free!'
          ).to_h
        )
        expect(released_cocina_object.structural.contains.first.structural.contains.first.access.to_h).to eq(
          Cocina::Models::FileAccess.new(
            view: 'dark',
            download: 'none'
          ).to_h
        )
        expect(UpdateObjectService).to have_received(:update)
      end
    end

    context 'when structural is nil' do
      let(:embargoed_cocina_object) do
        build(:dro).new(access:)
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
          Cocina::Models::DROAccess.new(
            view: 'citation-only',
            download: 'none',
            useAndReproductionStatement: 'Free!'
          ).to_h
        )
        expect(UpdateObjectService).to have_received(:update)
      end
    end
  end

  describe '#release_all' do
    let!(:item_with_releasable_embargo) do
      create(:repository_object).tap do |repo_obj|
        create(:repository_object_version, :with_releasable_embargo, :with_repository_object, repository_object: repo_obj)
        repo_obj.save!
      end
    end

    before do
      create(:repository_object_version, :with_repository_object)
      create(:repository_object_version, :with_repository_object, :with_embargo)
      allow(described_class).to receive(:release)
    end

    it 'releases based on db query' do
      described_class.release_all
      expect(described_class).to have_received(:release).with(item_with_releasable_embargo.external_identifier)
    end
  end
end
