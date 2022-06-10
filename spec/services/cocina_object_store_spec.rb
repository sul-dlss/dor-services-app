# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectStore do
  include Dry::Monads[:result]

  let(:store) { described_class.new }

  describe '#find' do
    context 'when object is not found in datastore' do
      it 'raises' do
        expect { store.find('druid:bc123df4567') }.to raise_error(CocinaObjectStore::CocinaObjectNotFoundError)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns Cocina::Models::DROWithMetadata' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::DROWithMetadata)
      end
    end

    context 'when object is an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns Cocina::Models::AdminPolicy' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::AdminPolicyWithMetadata)
      end
    end

    context 'when object is a Collection' do
      let(:ar_cocina_object) { create(:ar_collection) }

      it 'returns Cocina::Models::Collection' do
        expect(store.find(ar_cocina_object.external_identifier)).to be_instance_of(Cocina::Models::CollectionWithMetadata)
      end
    end
  end

  describe '#exists?' do
    context 'when object is not found in datastore' do
      it 'returns false' do
        expect(store.exists?('druid:bc123df4567')).to be(false)
      end
    end

    context 'when object is a DRO' do
      let(:ar_cocina_object) { create(:ar_dro) }

      it 'returns true' do
        expect(store.exists?(ar_cocina_object.external_identifier)).to be(true)
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

  describe '#save' do
    before do
      allow(Cocina::ObjectValidator).to receive(:validate)
    end

    context 'when object is a DRO' do
      context 'when skipping lock (e.g., for a create)' do
        let(:cocina_object) do
          Cocina::Models::DRO.new({
                                    cocinaVersion: '0.0.1',
                                    externalIdentifier: 'druid:xz456jk0987',
                                    type: Cocina::Models::ObjectType.book,
                                    label: 'Test DRO',
                                    version: 1,
                                    description: {
                                      title: [{ value: 'Test DRO' }],
                                      purl: 'https://purl.stanford.edu/xz456jk0987'
                                    },
                                    access: { view: 'world', download: 'world' },
                                    administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                    structural: {},
                                    identification: { sourceId: 'sul:123' }
                                  })
        end

        it 'saves to datastore' do
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
          expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::DROWithMetadata
          expect(Dro.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
        end
      end

      context 'when checking lock succeeds' do
        let(:ar_cocina_object) { create(:ar_dro) }
        let(:lock) { "#{ar_cocina_object.external_identifier}=0" }

        let(:cocina_object) do
          Cocina::Models.with_metadata(ar_cocina_object.to_cocina, lock, created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
        end

        let(:changed_cocina_object) do
          cocina_object.new(label: 'new label')
        end

        it 'saves to datastore' do
          expect(store.save(changed_cocina_object)).to be_kind_of Cocina::Models::DROWithMetadata
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
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new({
                                          cocinaVersion: '0.0.1',
                                          externalIdentifier: 'druid:jt959wc5586',
                                          type: Cocina::Models::ObjectType.admin_policy,
                                          label: 'Test Admin Policy',
                                          version: 1,
                                          administrative: {
                                            hasAdminPolicy: 'druid:hy787xj5878',
                                            hasAgreement: 'druid:bb033gt0615',
                                            accessTemplate: { view: 'world', download: 'world' }
                                          }
                                        })
      end

      it 'saves to datastore' do
        expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
        expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::AdminPolicyWithMetadata
        expect(AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
      end
    end

    context 'when object is a Collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new({
                                         cocinaVersion: '0.0.1',
                                         externalIdentifier: 'druid:hp308wm0436',
                                         type: Cocina::Models::ObjectType.collection,
                                         label: 'Test Collection',
                                         description: {
                                           title: [{ value: 'Test Collection' }],
                                           purl: 'https://purl.stanford.edu/hp308wm0436'
                                         },
                                         version: 1,
                                         access: { view: 'world' },
                                         administrative: {
                                           hasAdminPolicy: 'druid:hy787xj5878'
                                         },
                                         identification: { sourceId: 'sul:123' }
                                       })
      end

      it 'saves to datastore' do
        expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).to be_nil
        expect(store.save(cocina_object, skip_lock: true)).to be_kind_of Cocina::Models::CollectionWithMetadata
        expect(Collection.find_by(external_identifier: cocina_object.externalIdentifier)).not_to be_nil
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object) do
        build(:collection, source_id: 'sul:PC0170_s3_USC_2010-10-09_141959_0031')
      end

      before do
        # Create a duplicate record with the same sourceId
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

  describe '#create' do
    let(:druid) { 'druid:bc123df4567' }
    let(:catalog_links) { [] }

    let(:lock) { "#{druid}=0" }

    before do
      allow(Cocina::ObjectValidator).to receive(:validate)
      allow(Notifications::ObjectCreated).to receive(:publish)
      allow(store).to receive(:merge_access_for).and_return(requested_cocina_object)
      allow(store).to receive(:add_project_tag)
      allow(SuriService).to receive(:mint_id).and_return(druid)
      allow(EventFactory).to receive(:create)
      allow(RefreshMetadataAction).to receive(:run)
    end

    context 'when a DRO' do
      let(:requested_cocina_object) { build(:request_dro) }

      it 'persists it' do
        expect do
          expect(store.create(requested_cocina_object)).to be_kind_of Cocina::Models::DROWithMetadata
        end.to change(Dro, :count).by(1)

        expect(Notifications::ObjectCreated).to have_received(:publish)
        expect(Cocina::ObjectValidator).to have_received(:validate).with(requested_cocina_object)
        expect(store).to have_received(:merge_access_for).with(requested_cocina_object)
        expect(store).to have_received(:add_project_tag).with(druid, requested_cocina_object)
        expect(ObjectVersion.current_version(druid).tag).to eq('1.0.0')
        expect(EventFactory).to have_received(:create).with(druid:, event_type: 'registration', data: Hash)
        expect(RefreshMetadataAction).not_to have_received(:run)
      end
    end

    context 'when a Collection' do
      let(:requested_cocina_object) { build(:request_collection) }

      it 'persists it' do
        expect do
          expect(store.create(requested_cocina_object)).to be_kind_of Cocina::Models::CollectionWithMetadata
        end.to change(Collection, :count).by(1)
        expect(Notifications::ObjectCreated).to have_received(:publish)
        expect(Cocina::ObjectValidator).to have_received(:validate).with(requested_cocina_object)
        expect(store).to have_received(:merge_access_for).with(requested_cocina_object)
        expect(store).to have_received(:add_project_tag).with(druid, requested_cocina_object)
        expect(ObjectVersion.current_version(druid).tag).to eq('1.0.0')
        expect(EventFactory).to have_received(:create).with(druid:, event_type: 'registration', data: Hash)
        expect(RefreshMetadataAction).not_to have_received(:run)
      end
    end

    context 'when refreshing from symphony with a refresh=true catkey' do
      let(:requested_cocina_object) { build(:request_dro, catkeys: ['999123']) }
      let(:description_props) do
        {
          title: [{ value: 'The Well-Grounded Rubyist' }],
          purl: Purl.for(druid:)
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
      end

      it 'adds to description' do
        expect(store.create(requested_cocina_object).description.title.first.value).to eq 'The Well-Grounded Rubyist'
        expect(RefreshMetadataAction).to have_received(:run).with(identifiers: ['catkey:999123'], cocina_object: requested_cocina_object, druid:)
      end
    end

    context 'when skips refreshing from symphony with a refresh=false catkey' do
      let(:requested_cocina_object) { build(:request_dro).new(identification:) }
      let(:identification) do
        { sourceId: 'sul:1234', catalogLinks: [{ catalog: 'symphony', catalogRecordId: '999123', refresh: false }] }
      end

      it 'does not add to description' do
        store.create(requested_cocina_object)
        expect(RefreshMetadataAction).not_to have_received(:run)
      end
    end

    context 'when fails refreshing from symphony' do
      let(:requested_cocina_object) { build(:request_dro, catkeys: ['999123']) }

      before do
        allow(RefreshMetadataAction).to receive(:run).and_return(Failure())
      end

      it 'does not cause a failure' do
        store.create(requested_cocina_object)
        expect(RefreshMetadataAction).to have_received(:run).with(identifiers: ['catkey:999123'], cocina_object: requested_cocina_object, druid:)
      end
    end

    context 'when there is no description' do
      let(:requested_cocina_object) do
        Cocina::Models::RequestDRO.new(build(:request_dro, label: 'Roadside Geology of Utah').to_h.except(:description))
      end

      it 'creates a description from label' do
        expect(store.create(requested_cocina_object).description.title.first.value).to eq 'Roadside Geology of Utah'
      end
    end

    context 'when there is structural' do
      let(:requested_cocina_object) do
        build(:request_dro).new(
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
              # File already has identifiers
              {
                type: Cocina::Models::FileSetType.file,
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
        )
      end

      before do
        allow(SecureRandom).to receive(:uuid).and_return('abc123')
      end

      it 'adds external identifiers' do
        filesets = store.create(requested_cocina_object).structural.contains
        expect(filesets.first.externalIdentifier).to eq 'https://cocina.sul.stanford.edu/fileSet/bc123df4567-abc123'
        expect(filesets.first.structural.contains.first.externalIdentifier).to eq 'https://cocina.sul.stanford.edu/file/bc123df4567-abc123/00001.html'
        expect(filesets.last.structural.contains.first.externalIdentifier).to eq 'https://cocina.sul.stanford.edu/file/gg777gg7777/334-567-890/00002.html'
      end
    end

    context 'when assigning DOI' do
      let(:requested_cocina_object) do
        build(:request_dro)
      end

      it 'adds DOI to identification' do
        result = store.create(requested_cocina_object, assign_doi: true)
        expect(result.identification.doi).to eq '10.80343/bc123df4567'
      end
    end
  end

  describe '#destroy' do
    let!(:dro) { create(:ar_dro) }

    before do
      allow(Notifications::ObjectDeleted).to receive(:publish)
    end

    it 'destroys the object' do
      described_class.destroy(dro.external_identifier)
      expect(Dro).not_to exist(dro.external_identifier)
      expect(Notifications::ObjectDeleted).to have_received(:publish)
    end
  end
end
