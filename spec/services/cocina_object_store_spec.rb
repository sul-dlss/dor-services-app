# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  include Dry::Monads[:result]

  describe 'to Fedora' do
    let(:item) { instance_double(Dor::Item) }
    let(:date) { Time.zone.now }
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, to_h: cocina_hash) }

    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_hash) { { fake: 'hash' } }

    before do
      allow(ActiveFedora::ContentModel).to receive(:models_asserted_by).and_return(['info:fedora/afmodel:Item'])
      allow(item).to receive(:create_date).and_return(date)
      allow(item).to receive(:modified_date).and_return(date)
      allow(Cocina::ObjectValidator).to receive(:validate)
    end

    describe '#find' do
      context 'when DRO is found' do
        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
        end

        it 'returns Cocina object' do
          expect(described_class.find(druid)).to eq cocina_object
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
    end

    describe '#find_with_timestamps' do
      context 'when DRO is found' do
        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
        end

        it 'returns Cocina object adn the timestamps' do
          expect(described_class.find_with_timestamps(druid)).to eq [cocina_object, date, date]
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::Mapper).to have_received(:build).with(item)
        end
      end

      context 'when DRO is not found' do
        before do
          allow(Dor).to receive(:find).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'returns Cocina object' do
          expect { described_class.find_with_timestamps(druid) }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
        end
      end

      context 'when postgres find is enabled' do
        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
        end

        context 'when found in postgres' do
          let!(:ar_cocina_object) { create(:dro) }

          it 'returns from postgres' do
            expect(described_class.find_with_timestamps(ar_cocina_object.external_identifier)).to match([instance_of(Cocina::Models::DRO), kind_of(Time),
                                                                                                         kind_of(Time)])
          end
        end

        context 'when not found in postgres' do
          before do
            allow(Dor).to receive(:find).and_return(item)
            allow(Cocina::Mapper).to receive(:build).and_return(cocina_object)
          end

          it 'returns from fedora' do
            expect(described_class.find_with_timestamps(druid)).to eq [cocina_object, date, date]
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
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Notifications::ObjectUpdated).to receive(:publish)
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run)
          allow(cocina_object_store).to receive(:add_tags_for_update)
          allow(EventFactory).to receive(:create)
        end

        it 'maps and saves to Fedora' do
          expect(cocina_object_store.save(cocina_object)).to be cocina_object
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::ObjectUpdater).to have_received(:run).with(item, cocina_object)
          expect(Notifications::ObjectUpdated).to have_received(:publish).with(model: cocina_object, created_at: item.create_date, modified_at: item.modified_date)
          expect(Cocina::ObjectValidator).to have_received(:validate).with(cocina_object)
          expect(cocina_object_store).to have_received(:add_tags_for_update).with(cocina_object)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: true, request: cocina_hash })
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
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
          allow(described_class).to receive(:new).and_return(cocina_object_store)
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run)
          allow(cocina_object_store).to receive(:cocina_to_ar_save)
          allow(cocina_object_store).to receive(:ar_exists?).and_return(true)
          allow(cocina_object_store).to receive(:add_tags_for_update)
          allow(EventFactory).to receive(:create)
        end

        it 'maps and saves to Fedora' do
          expect(described_class.save(cocina_object)).to be cocina_object
          expect(Dor).to have_received(:find).with(druid)
          expect(Cocina::ObjectUpdater).to have_received(:run).with(item, cocina_object)
          expect(cocina_object_store).to have_received(:cocina_to_ar_save).with(cocina_object)
          expect(cocina_object_store).to have_received(:ar_exists?).with(druid)
        end
      end

      context 'when validation error' do
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Cocina::ObjectValidator).to receive(:validate).and_raise(Cocina::ValidationError, 'Ooops.')
          allow(EventFactory).to receive(:create)
          allow(cocina_object).to receive(:to_h).and_return(cocina_hash)
        end

        it 'raises' do
          expect { cocina_object_store.save(cocina_object) }.to raise_error(Cocina::ValidationError)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: false, request: cocina_hash, error: 'Ooops.' })
        end
      end

      context 'when Fedora-specific error' do
        let(:cocina_object_store) { described_class.new }

        before do
          allow(Dor).to receive(:find).and_return(item)
          allow(Cocina::ObjectUpdater).to receive(:run).and_raise(Cocina::Mapper::MapperError)
          allow(EventFactory).to receive(:create)
          allow(cocina_object).to receive(:to_h).and_return(cocina_hash)
        end

        it 'raises' do
          expect { cocina_object_store.save(cocina_object) }.to raise_error(Cocina::Mapper::MapperError)
          expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'update', data: { success: false, request: cocina_hash, error: 'Cocina::Mapper::MapperError' })
        end
      end
    end

    describe '#create' do
      let(:cocina_object_store) { described_class.new }
      let(:requested_cocina_object) do
        instance_double(Cocina::Models::RequestDRO, admin_policy?: false, identification: request_identification, to_h: cocina_hash, description: request_description)
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
        allow(SynchronousIndexer).to receive(:reindex_remotely)
        allow(EventFactory).to receive(:create)
        allow(RefreshMetadataAction).to receive(:run)
        allow(Cocina::Models).to receive(:build).and_return(cocina_object)
      end

      it 'maps and saves to Fedora' do
        expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
        expect(Cocina::ObjectCreator).to have_received(:create).with(cocina_object, druid: druid)
        expect(Notifications::ObjectCreated).to have_received(:publish).with(model: cocina_object, created_at: kind_of(Time), modified_at: kind_of(Time))
        expect(Cocina::ObjectValidator).to have_received(:validate).with(requested_cocina_object)
        expect(cocina_object_store).to have_received(:merge_access_for).with(requested_cocina_object)
        expect(cocina_object_store).to have_received(:add_tags_for_create).with(druid, cocina_object)
        expect(SynchronousIndexer).to have_received(:reindex_remotely).with(druid)
        expect(ObjectVersion.current_version(druid).tag).to eq('1.0.0')
        expect(EventFactory).to have_received(:create).with(druid: druid, event_type: 'registration', data: cocina_hash)
        expect(RefreshMetadataAction).not_to have_received(:run)
        expect(Cocina::Models).to have_received(:build).with({
                                                               externalIdentifier: druid
                                                             })
      end

      context 'when refreshing from symphony' do
        let(:catalog_links) { [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'abc123')] }
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
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
          expect(RefreshMetadataAction).to have_received(:run).with(identifiers: ['catkey:abc123'], cocina_object: requested_cocina_object, druid: druid)
          expect(requested_cocina_object).to have_received(:new).with(label: 'The Well-Grounded Rubyist', description: { title: [{ value: 'The Well-Grounded Rubyist' }] })
        end
      end

      context 'when fails refreshing from symphony' do
        let(:catalog_links) { [Cocina::Models::CatalogLink.new(catalog: 'symphony', catalogRecordId: 'abc123')] }

        before do
          allow(RefreshMetadataAction).to receive(:run).and_return(Failure())
        end

        it 'does not add to description' do
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
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
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
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
                                                                 }
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
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
          expect(requested_cocina_object).to have_received(:new).with(description: { title: [{ value: 'Roadside Geology of Utah' }] })
        end
      end

      context 'when there is structural' do
        let(:cocina_hash) do
          {
            structural: {
              contains: [
                {
                  type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                  label: 'Page 1', version: 1,
                  structural: {
                    contains: [
                      {
                        type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
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
                        access: { access: 'dark', download: 'none' },
                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                      }
                    ]
                  }
                },
                # Already has identifiers
                {
                  type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                  externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/gg777gg7777/334-567-890',
                  label: 'Page 2', version: 1,
                  structural: {
                    contains: [
                      {
                        type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                        externalIdentifier: 'http://cocina.sul.stanford.edu/file/gg777gg7777/334-567-890/00002.html',
                        label: '00002.html', filename: '00002.html', size: 0,
                        version: 1, hasMimeType: 'text/html',
                        hasMessageDigests: [],
                        access: { access: 'dark', download: 'none' },
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
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
          expect(Cocina::Models).to have_received(:build).with({
                                                                 externalIdentifier: druid,
                                                                 structural: {
                                                                   contains: [
                                                                     {
                                                                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                                                                       externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/bc123df4567-abc123',
                                                                       label: 'Page 1', version: 1,
                                                                       structural: {
                                                                         contains: [
                                                                           {
                                                                             type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                                             externalIdentifier: 'http://cocina.sul.stanford.edu/file/bc123df4567-abc123/00001.html',
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
                                                                             access: { access: 'dark', download: 'none' },
                                                                             administrative: { publish: false, sdrPreserve: true, shelve: false }
                                                                           }
                                                                         ]
                                                                       }
                                                                     },
                                                                     {
                                                                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                                                                       externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/gg777gg7777/334-567-890',
                                                                       label: 'Page 2', version: 1,
                                                                       structural: {
                                                                         contains: [
                                                                           {
                                                                             type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                                             externalIdentifier: 'http://cocina.sul.stanford.edu/file/gg777gg7777/334-567-890/00002.html',
                                                                             label: '00002.html', filename: '00002.html', size: 0,
                                                                             version: 1, hasMimeType: 'text/html',
                                                                             hasMessageDigests: [],
                                                                             access: { access: 'dark', download: 'none' },
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
          expect(cocina_object_store.create(requested_cocina_object, assign_doi: true)).to be cocina_object
          expect(identification).to have_received(:new).with(doi: '10.80343/bc123df4567')
          expect(cocina_object).to have_received(:new).with(identification: updated_identification)
        end
      end

      context 'when postgres create is enabled' do
        before do
          allow(Settings.enabled_features).to receive(:postgres).and_return(true)
          allow(cocina_object_store).to receive(:cocina_to_ar_save)
        end

        it 'save to postgres' do
          expect(cocina_object_store.create(requested_cocina_object)).to be cocina_object
          expect(cocina_object_store).to have_received(:cocina_to_ar_save).with(cocina_object)
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

    describe '#add_tags_for_update' do
      let(:cocina_object_store) { described_class.new }
      let(:cocina_object) { instance_double(Cocina::Models::Collection, dro?: false, collection?: true, administrative: administrative, externalIdentifier: druid) }
      let(:administrative) { instance_double(Cocina::Models::Administrative, partOfProject: 'Google Books') }

      before do
        allow(AdministrativeTags).to receive(:create)
      end

      context 'when creating a new project tag' do
        it 'creates tag' do
          cocina_object_store.send(:add_tags_for_update, cocina_object)
          expect(AdministrativeTags).to have_received(:create).with(identifier: druid, tags: ['Project : Google Books'])
        end
      end

      context 'when multiple project tags already exists' do
        before do
          allow(AdministrativeTags).to receive(:for).and_return(['Project : Phoenix', 'Project : Google Books'])
        end

        it 'raises' do
          expect { cocina_object_store.send(:add_tags_for_update, cocina_object) }.to raise_error(/Too many tags for prefix/)
        end
      end

      context 'when creating a new project tag with an existing project subtag' do
        before do
          allow(AdministrativeTags).to receive(:for).and_return(['Project : Google Books : Special'])
        end

        it 'creates tag' do
          cocina_object_store.send(:add_tags_for_update, cocina_object)
          expect(AdministrativeTags).to have_received(:create).with(identifier: druid, tags: ['Project : Google Books'])
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
        let(:ar_cocina_object) { create(:dro) }

        it 'returns Cocina::Models::DRO' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to match([instance_of(Cocina::Models::DRO), kind_of(Time), kind_of(Time)])
        end
      end

      context 'when object is an AdminPolicy' do
        let(:ar_cocina_object) { create(:admin_policy) }

        it 'returns Cocina::Models::AdminPolicy' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to match([instance_of(Cocina::Models::AdminPolicy), kind_of(Time), kind_of(Time)])
        end
      end

      context 'when object is a Collection' do
        let(:ar_cocina_object) { create(:collection) }

        it 'returns Cocina::Models::Collection' do
          expect(store.send(:ar_to_cocina_find, ar_cocina_object.external_identifier)).to match([instance_of(Cocina::Models::Collection), kind_of(Time), kind_of(Time)])
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
        let(:ar_cocina_object) { create(:dro) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end

      context 'when object is an AdminPolicy' do
        let(:ar_cocina_object) { create(:admin_policy) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end

      context 'when object is a Collection' do
        let(:ar_cocina_object) { create(:collection) }

        it 'returns true' do
          expect(store.ar_exists?(ar_cocina_object.external_identifier)).to be(true)
        end
      end
    end

    describe '#cocina_to_ar_save' do
      let(:store) { described_class.new }

      context 'when object is a DRO' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: 'druid:xz456jk0987',
                                    type: Cocina::Models::Vocab.book,
                                    label: 'Test DRO',
                                    version: 1,
                                    description: {
                                      title: [{ value: 'Test DRO' }],
                                      purl: 'https://purl.stanford.edu/xz456jk0987'
                                    },
                                    access: { access: 'world', download: 'world' },
                                    administrative: { hasAdminPolicy: 'druid:hy787xj5878' }
                                  })
        end

        it 'saves to datastore' do
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to match([kind_of(Time), kind_of(Time)])
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when object is an AdminPolicy' do
        let(:cocina_object) do
          Cocina::Models::AdminPolicy.new({
                                            cocinaVersion: '0.0.1',
                                            externalIdentifier: 'druid:jt959wc5586',
                                            type: Cocina::Models::Vocab.admin_policy,
                                            label: 'Test Admin Policy',
                                            version: 1,
                                            administrative: {
                                              hasAdminPolicy: 'druid:hy787xj5878',
                                              hasAgreement: 'druid:bb033gt0615',
                                              defaultAccess: { access: 'world', download: 'world' }
                                            }
                                          })
        end

        it 'saves to datastore' do
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to match([kind_of(Time), kind_of(Time)])
          expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when object is a Collection' do
        let(:cocina_object) do
          Cocina::Models::Collection.new({
                                           cocinaVersion: '0.0.1',
                                           externalIdentifier: 'druid:hp308wm0436',
                                           type: Cocina::Models::Vocab.collection,
                                           label: 'Test Collection',
                                           description: {
                                             title: [{ value: 'Test Collection' }],
                                             purl: 'https://purl.stanford.edu/hp308wm0436'
                                           },
                                           version: 1,
                                           access: { access: 'world' }
                                         })
        end

        it 'saves to datastore' do
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.send(:cocina_to_ar_save, cocina_object)).to match([kind_of(Time), kind_of(Time)])
          expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end
    end
  end
end
