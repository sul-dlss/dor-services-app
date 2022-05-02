# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  include Dry::Monads[:result]

  let(:date) { Time.zone.now }

  let(:lock) { "#{druid}=#{date.to_datetime.iso8601}" }

  describe 'to Fedora' do
    let(:item) { instance_double(Dor::Item, pid: druid, modified_date: date.to_time) }
    let(:cocina_object) { build(:dro, id: druid) }
    let(:cocina_object_with_metadata) do
      Cocina::Models.with_metadata(cocina_object, lock, created: date, modified: date)
    end

    let(:druid) { 'druid:bc123df4567' }

    before do
      allow(ActiveFedora::ContentModel).to receive(:models_asserted_by).and_return(['info:fedora/afmodel:Item'])
      allow(item).to receive(:create_date).and_return(date)
      allow(item).to receive(:modified_date).and_return(date)
      allow(Cocina::ObjectValidator).to receive(:validate)
    end

    describe '#find' do
      context 'when DRO is found' do
        let(:found_cocina_object) { described_class.find(druid) }

        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
        end

        it 'returns Cocina object' do
          expect(found_cocina_object).to cocina_object_with cocina_object
          expect(found_cocina_object).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::Mapper).to have_received(:build).with(item)
        end
      end

      context 'when DRO is not found' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'returns Cocina object' do
          expect { described_class.find(druid) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when some other error raised' do
        before do
          allow(Dor).to receive(:find).and_raise(Rubydora::FedoraInvalidRequest)
        end

        it 're-raises with more info' do
          prefix = 'Unable to find Fedora object or map to cmodel - is identityMetadata DS empty?'
          expect { described_class.find(druid) }.to raise_error(Rubydora::FedoraInvalidRequest, a_string_starting_with(prefix))
        end
      end

      context 'when postgres find is enabled' do
        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
        end

        context 'when found in postgres' do
          let!(:ar_cocina_object) { create(:ar_dro) }

          it 'returns from postgres' do
            expect(described_class.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
          end
        end

        context 'when not found in postgres' do
          before do
            allow(Dor).to receive(:find).and_return(item)
            allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
          end

          it 'returns from fedora' do
            expect(described_class.find(druid)).to cocina_object_with cocina_object
            expect(Dor).to have_received(:find).with(druid)
          end
        end
      end
    end

    describe '#exists?' do
      context 'when DRO is found' do
        before do
          allow(Dor).to receive(:find).and_return(item)
        end

        it 'returns true' do
          expect(described_class.exists?(druid)).to be(true)
          expect(Dor).to have_received(:find).with(druid)
        end
      end

      context 'when DRO is not found' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'returns false' do
          expect(described_class.exists?(druid)).to be(false)
        end
      end
    end

    describe '#save' do
      context 'when object is found in datastore' do
        let(:saved_cocina_object) { cocina_object_store.save(cocina_object_with_metadata) }
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Notifications::ObjectUpdated).to receive(:publish)
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run)
          allow(cocina_object_store).to receive(:add_tags_for_update)
          allow(EventFactory).to receive(:create)
        end

        it 'maps and saves to Fedora' do
          expect(saved_cocina_object).to cocina_object_with cocina_object
          expect(saved_cocina_object).to be_instance_of(Cocina::Models::DROWithMetadata)
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::ObjectUpdater).to have_received(:run).with(item, cocina_object)
          expect(Notifications::ObjectUpdated).to have_received(:publish).with(model: cocina_object, created_at: item.create_date, modified_at: item.modified_date)
          expect(Cocina::ObjectValidator).to have_received(:validate).with(cocina_object_with_metadata)
          expect(cocina_object_store).to have_received(:add_tags_for_update).with(cocina_object_with_metadata)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: true, request: cocina_object.to_h })
        end
      end

      context 'when stale lock' do
        let(:saved_cocina_object) { cocina_object_store.save(cocina_object_with_metadata) }
        let(:cocina_object_store) { described_class.new }

        let(:lock) { 'bad lock' }

        before do
          allow(Dor).to receive(:find).and_return(item)
        end

        it 'raises' do
          expect { cocina_object_store.save(cocina_object_with_metadata) }.to raise_error(CocinaObjectStore::StaleLockError)
        end
      end

      context 'when object is not found in datastore' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'raises' do
          expect { described_class.save(cocina_object) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when postgres update is enabled' do
        let(:saved_cocina_object) { cocina_object_store.save(cocina_object_with_metadata) }
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
          allow(described_class).to receive(:new).and_return(cocina_object_store)
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run)
          allow(cocina_object_store).to receive(:ar_exists?).and_return(true)
          allow(cocina_object_store).to receive(:add_tags_for_update)
          allow(EventFactory).to receive(:create)
        end

        context 'when object found in datastore' do
          before do
            allow(cocina_object_store).to receive(:cocina_to_ar_save).and_return([date, date, 'abc123'])
          end

          it 'maps and saves to Fedora and Postgres' do
            expect(saved_cocina_object).to cocina_object_with(cocina_object)
            expect(saved_cocina_object).to be_instance_of(Cocina::Models::DROWithMetadata)
            expect(Dor).to have_received(:find).with(druid)
            expect(Cocina::ObjectUpdater).to have_received(:run).with(item, cocina_object)
            expect(cocina_object_store).to have_received(:cocina_to_ar_save).with(cocina_object_with_metadata, skip_lock: false)
            expect(cocina_object_store).to have_received(:ar_exists?).with(druid)
          end
        end

        context 'when stale lock' do
          before do
            allow(cocina_object_store).to receive(:cocina_to_ar_save).and_raise(CocinaObjectStore::StaleLockError)
          end

          it 'raises' do
            expect { cocina_object_store.save(cocina_object_with_metadata) }.to raise_error(CocinaObjectStore::StaleLockError)
            # When PG stale lock, don't save to Fedora.
            expect(Cocina::ObjectUpdater).not_to have_received(:run)
            expect(Dor).not_to have_received(:find)
          end
        end
      end

      context 'when validation error' do
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Cocina::ObjectValidator).to receive(:validate).and_raise(Cocina::ValidationError, 'Ooops.')
          allow(EventFactory).to receive(:create)
        end

        it 'raises' do
          expect { cocina_object_store.save(cocina_object_with_metadata) }.to raise_error(Cocina::ValidationError)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: false, request: cocina_object.to_h, error: 'Ooops.' })
        end
      end

      context 'when Fedora-specific error' do
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run).and_raise(Cocina::Mapper::MapperError)
          allow(EventFactory).to receive(:create)
        end

        it 'raises' do
          expect { cocina_object_store.save(cocina_object_with_metadata) }.to raise_error(Cocina::Mapper::MapperError)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: false, request: cocina_object.to_h, error: 'Cocina::Mapper::MapperError' })
        end
      end
    end

    describe '#create' do
      let(:cocina_object_store) { described_class.new }
      let(:requested_cocina_object) do
        instance_double(Cocina::Models::RequestDRO, admin_policy?: false, identification: request_identification, to_h: cocina_hash, description: request_description, dro?: true,
                                                    collection?: false)
      end
      let(:request_identification) { instance_double(Cocina::Models::RequestIdentification, catalogLinks: catalog_links) }
      let(:request_description) { instance_double(Cocina::Models::RequestDescription) }
      let(:catalog_links) { [] }
      let(:cocina_hash) { {} }

      before do
        allow(Notifications::ObjectCreated).to receive(:publish)
        allow(Cocina::ObjectCreator).to receive(:create).and_return(item)
        allow(cocina_object_store).to receive(:merge_access_for).and_return(requested_cocina_object)
        allow(cocina_object_store).to receive(:add_tags_for_create)
        allow(SuriService).to receive(:mint_id).and_return(druid)
        allow(SynchronousIndexer).to receive(:reindex_remotely_from_cocina)
        allow(EventFactory).to receive(:create)
        allow(RefreshMetadataAction).to receive(:run)
        allow(Cocina::Models).to receive(:build).and_return(cocina_object)
      end

      context 'when a DRO' do
        it 'maps and saves to Fedora' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(Cocina::ObjectCreator).to have_received(:create).with(cocina_object, druid: druid)
          expect(Notifications::ObjectCreated).to have_received(:publish).with(model: cocina_object, created_at: kind_of(DateTime), modified_at: kind_of(DateTime))
          expect(Cocina::ObjectValidator).to have_received(:validate).with(requested_cocina_object)
          expect(cocina_object_store).to have_received(:merge_access_for).with(requested_cocina_object)
          expect(cocina_object_store).to have_received(:add_tags_for_create).with(druid, requested_cocina_object)
          expect(SynchronousIndexer).to have_received(:reindex_remotely_from_cocina).with(cocina_object: cocina_object, created_at: kind_of(DateTime), updated_at: kind_of(DateTime))
          expect(ObjectVersion.current_version(druid).tag).to eq('1.0.0')
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'registration', data: cocina_object.to_h)
          expect(RefreshMetadataAction).not_to have_received(:run)
          expect(Cocina::Models).to have_received(:build).with({
                                                                 externalIdentifier: druid,
                                                                 structural: {}
                                                               })
        end
      end

      context 'when a Collection' do
        let(:requested_cocina_object) do
          instance_double(Cocina::Models::RequestCollection, admin_policy?: false, identification: nil, to_h: cocina_hash, description: request_description, dro?: false, collection?: true)
        end

        it 'maps and saves to Fedora' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(Cocina::ObjectCreator).to have_received(:create).with(cocina_object, druid: druid)
          expect(Notifications::ObjectCreated).to have_received(:publish).with(model: cocina_object, created_at: kind_of(DateTime), modified_at: kind_of(DateTime))
          expect(Cocina::ObjectValidator).to have_received(:validate).with(requested_cocina_object)
          expect(cocina_object_store).to have_received(:merge_access_for).with(requested_cocina_object)
          expect(cocina_object_store).to have_received(:add_tags_for_create).with(druid, requested_cocina_object)
          expect(SynchronousIndexer).to have_received(:reindex_remotely_from_cocina).with(cocina_object: cocina_object, created_at: kind_of(DateTime), updated_at: kind_of(DateTime))
          expect(ObjectVersion.current_version(druid).tag).to eq('1.0.0')
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'registration', data: cocina_object.to_h)
          expect(RefreshMetadataAction).not_to have_received(:run)
          expect(Cocina::Models).to have_received(:build).with({
                                                                 externalIdentifier: druid,
                                                                 identification: {}
                                                               })
        end
      end

      context 'when refreshing from symphony' do
        let(:catalog_links) { [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'abc123', refresh: true)] }
        let(:description_props) do
          {
            title: [{ value: 'The Well-Grounded Rubyist' }],
            purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
          }
        end

        let(:mods) do
          Nokogiri::XML(
            <<~XML
              <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
                <titleInfo>
                  <title>The Well-Grounded Rubyist</title>
                </titleInfo>
              </mods>
            XML
          )
        end

        before do
          allow(RefreshMetadataAction).to receive(:run).and_return(Success(RefreshMetadataAction::Result.new(description_props, mods)))
          allow(requested_cocina_object).to receive(:new).and_return(requested_cocina_object)
        end

        it 'adds to description' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(RefreshMetadataAction).to have_received(:run).with(identifiers: ['catkey:abc123'], cocina_object: requested_cocina_object, druid: druid)
          expect(requested_cocina_object).to have_received(:new).with(label: 'The Well-Grounded Rubyist', description: { title: [{ value: 'The Well-Grounded Rubyist' }] })
        end
      end

      context 'when fails refreshing from symphony' do
        let(:catalog_links) { [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'abc123', refresh: true)] }

        before do
          allow(RefreshMetadataAction).to receive(:run).and_return(Failure())
        end

        it 'does not add to description' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(RefreshMetadataAction).to have_received(:run).with(identifiers: ['catkey:abc123'], cocina_object: requested_cocina_object, druid: druid)
        end
      end

      context 'when there is description' do
        let(:cocina_hash) do
          {
            description: {
              note: [
                {
                  type: 'abstract',
                  value: 'I am an abstract'
                },
                {
                  type: 'preferred citation',
                  value: 'Zappa, F. (2013) :link:'
                }
              ],
              title: [
                {
                  value: 'The Lost Episodes'
                }
              ]
            }
          }
        end

        it 'adds purl and updates notes in description' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(Cocina::Models).to have_received(:build).with({
                                                                 externalIdentifier: druid,
                                                                 description: {
                                                                   note: [
                                                                     {
                                                                       type: 'abstract',
                                                                       value: 'I am an abstract'
                                                                     },
                                                                     {
                                                                       type: 'preferred citation',
                                                                       value: 'Zappa, F. (2013) https://purl.stanford.edu/bc123df4567'
                                                                     }
                                                                   ],
                                                                   title: [
                                                                     {
                                                                       value: 'The Lost Episodes'
                                                                     }
                                                                   ],
                                                                   purl: 'https://purl.stanford.edu/bc123df4567'
                                                                 },
                                                                 structural: {}
                                                               })
        end
      end

      context 'when there is no description' do
        let(:request_description) { nil }

        before do
          allow(requested_cocina_object).to receive(:new).and_return(requested_cocina_object)
          allow(requested_cocina_object).to receive(:label).and_return('Roadside Geology of Utah')
        end

        it 'adds a description from label' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(requested_cocina_object).to have_received(:new).with(description: { title: [{ value: 'Roadside Geology of Utah' }] })
        end
      end

      context 'when there is structural' do
        let(:cocina_hash) do
          {
            structural: {
              contains: [
                {
                  type: Cocina::Models::FileSetType.file,
                  label: 'Page 1', version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        label: '00001.html',
                        filename: '00001.html',
                        size: 0,
                        version: 1,
                        hasMimeType: 'text/html',
                        use: 'transcription',
                        hasMessageDigests: [
                          {
                            type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                          }, {
                            type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                          }
                        ],
                        access: { view: 'dark', download: 'none' },
                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                      }
                    ]
                  }
                },
                # Already has identifiers
                {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777/334-567-890',
                  label: 'Page 2', version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777/334-567-890/00002.html',
                        label: '00002.html', filename: '00002.html', size: 0,
                        version: 1, hasMimeType: 'text/html',
                        hasMessageDigests: [],
                        access: { view: 'dark', download: 'none' },
                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                      }
                    ]
                  }
                }
              ]
            }
          }
        end

        before do
          allow(SecureRandom).to receive(:uuid).and_return('abc123')
        end

        it 'adds external identifiers' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(Cocina::Models).to have_received(:build).with({
                                                                 externalIdentifier: druid,
                                                                 structural: {
                                                                   contains: [
                                                                     {
                                                                       type: Cocina::Models::FileSetType.file,
                                                                       externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-abc123',
                                                                       label: 'Page 1', version: 1,
                                                                       structural: {
                                                                         contains: [
                                                                           {
                                                                             type: Cocina::Models::ObjectType.file,
                                                                             externalIdentifier: 'https://cocina.sul.stanford.edu/file/bc123df4567-abc123/00001.html',
                                                                             label: '00001.html',
                                                                             filename: '00001.html',
                                                                             size: 0,
                                                                             version: 1,
                                                                             hasMimeType: 'text/html',
                                                                             use: 'transcription',
                                                                             hasMessageDigests: [
                                                                               {
                                                                                 type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                                                                               }, {
                                                                                 type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                                                                               }
                                                                             ],
                                                                             access: { view: 'dark', download: 'none' },
                                                                             administrative: { publish: false, sdrPreserve: true, shelve: false }
                                                                           }
                                                                         ]
                                                                       }
                                                                     },
                                                                     {
                                                                       type: Cocina::Models::FileSetType.file,
                                                                       externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777/334-567-890',
                                                                       label: 'Page 2', version: 1,
                                                                       structural: {
                                                                         contains: [
                                                                           {
                                                                             type: Cocina::Models::ObjectType.file,
                                                                             externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777/334-567-890/00002.html',
                                                                             label: '00002.html', filename: '00002.html', size: 0,
                                                                             version: 1, hasMimeType: 'text/html',
                                                                             hasMessageDigests: [],
                                                                             access: { view: 'dark', download: 'none' },
                                                                             administrative: { publish: false, sdrPreserve: true, shelve: false }
                                                                           }
                                                                         ]
                                                                       }
                                                                     }
                                                                   ]
                                                                 }
                                                               })
        end
      end

      context 'when assigning DOI' do
        let(:identification) { instance_double(Cocina::Models::Identification) }
        let(:updated_identification) { instance_double(Cocina::Models::Identification) }

        before do
          allow(cocina_object).to receive(:identification).and_return(identification)
          allow(cocina_object).to receive(:new).and_return(cocina_object)
          allow(identification).to receive(:new).and_return(updated_identification)
        end

        it 'adds DOI to identification' do
          expect(cocina_object_store.create(requested_cocina_object, assign_doi: true)).to cocina_object_with cocina_object_with_metadata
          expect(identification).to have_received(:new).with(doi: '10.80343/bc123df4567')
          expect(cocina_object).to have_received(:new).with(identification: updated_identification)
        end
      end

      context 'when postgres create is enabled' do
        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
          allow(cocina_object_store).to receive(:cocina_to_ar_save).and_return([date, date, lock])
        end

        it 'save to postgres' do
          expect(cocina_object_store.create(requested_cocina_object)).to cocina_object_with cocina_object_with_metadata
          expect(cocina_object_store).to have_received(:cocina_to_ar_save).with(cocina_object, skip_lock: true)
        end
      end
    end

    describe '#destroy' do
      context 'when DRO is found' do
        let(:fedora_object) { instance_double(Dor::Item, destroy: nil) }

        before do
          allow(Dor).to receive(:find).and_return(fedora_object)
          allow(Notifications::ObjectDeleted).to receive(:publish)
          allow(described_class).to receive(:find).and_return(cocina_object)
        end

        it 'destroys Fedora object and notifies' do
          described_class.destroy(druid)
          expect(fedora_object).to have_received(:destroy)

          expect(Notifications::ObjectDeleted).to have_received(:publish).with(model: cocina_object, deleted_at: kind_of(Time))
        end
      end

      context 'when DRO is not found' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'raises' do
          expect { described_class.destroy(druid) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when postgres destroy is enabled' do
        let(:fedora_object) { instance_double(Dor::Item, destroy: nil) }

        let(:cocina_object_store) { described_class.new }

        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
          allow(Dor).to receive(:find).and_return(fedora_object)
          allow(described_class).to receive(:find).and_return(cocina_object)
          allow(described_class).to receive(:new).and_return(cocina_object_store)
          allow(cocina_object_store).to receive(:ar_exists?).and_return(true)
          allow(cocina_object_store).to receive(:ar_destroy)
        end

        it 'destroys Fedora object and ActiveRecord object' do
          described_class.destroy(druid)
          expect(fedora_object).to have_received(:destroy)
          expect(cocina_object_store).to have_received(:ar_destroy).with(druid)
        end
      end
    end
  end

  describe 'to ActiveRecord' do
    let(:store) { described_class.new }

    describe '#ar_to_cocina_find' do
      context 'when object is not found in datastore' do
        it 'raises' do
          expect { store.send(:ar_to_cocina_find, 'druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when object is a DRO' do
        let(:ar_cocina_object) { create(:ar_dro) }

        it 'returns Cocina::Models::DROWithMetadata' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
        end
      end

      context 'when object is an AdminPolicy' do
        let(:ar_cocina_object) { create(:ar_admin_policy) }

        it 'returns Cocina::Models::AdminPolicy' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::AdminPolicyWithMetadata)
        end
      end

      context 'when object is a Collection' do
        let(:ar_cocina_object) { create(:ar_collection) }

        it 'returns Cocina::Models::Collection' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::CollectionWithMetadata)
        end
      end
    end

    describe '#ar_exists?' do
      context 'when object is not found in datastore' do
        it 'returns false' do
          expect(store.ar_exists?('druid:bc123df4567')).to be(false)
        end
      end

      context 'when object is a DRO' do
        let(:ar_cocina_object) { create(:ar_dro) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end

      context 'when object is an AdminPolicy' do
        let(:ar_cocina_object) { create(:ar_admin_policy) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end

      context 'when object is a Collection' do
        let(:ar_cocina_object) { create(:ar_collection) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end
    end

    describe '#cocina_to_ar_save' do
      let(:store) { described_class.new }

      context 'when object is a DRO' do
        context 'when skipping lock (e.g., for a create)' do
          let(:cocina_object) { build(:dro) }

          it 'saves to datastore' do
            expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
            expect(store.send(:cocina_to_ar_save, cocina_object, skip_lock: true)).to match([kind_of(Time), kind_of(Time), kind_of(String)])
            expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
          end
        end

        context 'when checking lock succeeds' do
          let(:ar_cocina_object) { create(:ar_dro) }
          let(:lock) { "#{ar_cocina_object.external_identifier}=#{ar_cocina_object.lock}" }

          let(:cocina_object) do
            Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
          end

          let(:changed_cocina_object) do
            cocina_object.new(label: 'new label')
          end

          it 'saves to datastore' do
            expect(store.send(:cocina_to_ar_save, changed_cocina_object)).to match([kind_of(Time), kind_of(Time), kind_of(String)])
            expect(Dro.find_by(external_identifier: ar_cocina_object.external_identifier).label).to eq('new label')
          end
        end

        context 'when checking lock fails' do
          let!(:ar_cocina_object) { create(:ar_dro) }
          let(:lock) { '64e8320d19d62ddb73c501276c5655cf' }

          let(:cocina_object) do
            Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.updated_at.utc, modified: ar_cocina_object.updated_at.utc)
          end

          let(:changed_cocina_object) do
            cocina_object.new(label: 'new label')
          end

          it 'saves to datastore' do
            ar_cocina_object.label = 'someone else changed this label'
            ar_cocina_object.save!
            expect { store.send(:cocina_to_ar_save, changed_cocina_object) }.to raise_error(CocinaObjectStore::StaleLockError)
          end
        end
      end

      context 'when object is an AdminPolicy' do
        let(:cocina_object) { build(:admin_policy) }

        it 'saves to datastore' do
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object, skip_lock: true)).to match([kind_of(Time), kind_of(Time), kind_of(String)])
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when object is a Collection' do
        let(:cocina_object) { build(:collection) }

        it 'saves to datastore' do
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object, skip_lock: true)).to match([kind_of(Time), kind_of(Time), kind_of(String)])
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when sourceId is not unique' do
        let(:cocina_object) { build(:collection, source_id: 'sul:PC0170_s3_USC_2010-10-09_141959_0031') }

        before do
          store.send(:cocina_to_ar_save, cocina_object.new(
                                           externalIdentifier: 'druid:dd645sg2172',
                                           description: {
                                             title: [{ value: 'Test Collection' }],
                                             purl: 'https://purl.stanford.edu/dd645sg2172'
                                           }
                                         ), skip_lock: true)
        end

        it 'raises' do
          expect { store.send(:cocina_to_ar_save, cocina_object, skip_lock: true) }.to raise_error(Cocina::ValidationError)
        end
      end
    end
  end
end
