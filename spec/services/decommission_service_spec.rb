# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DecommissionService do
  let(:druid) { 'druid:hj185xx2222' }
  let(:cocina_object) do
    Cocina::Models.with_metadata(
      build(:dro, id: druid).new(access: { view: 'world' },
                                 administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                                 structural: {
                                   contains: [
                                     {
                                       type: Cocina::Models::FileSetType.file.to_s,
                                       externalIdentifier: 'hj185xx2222_1',
                                       label: 'Image 1',
                                       version: 3,
                                       structural: {
                                         contains: [
                                           {
                                             type: Cocina::Models::ObjectType.file.to_s,
                                             externalIdentifier: 'druid:hj185xx2222/not_shelved.jpg',
                                             label: 'not shelved',
                                             filename: 'not_shelved.jpg',
                                             size: 29_634,
                                             version: 3,
                                             hasMimeType: 'image/jpeg',
                                             hasMessageDigests: [
                                               {
                                                 type: 'sha1',
                                                 digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                               },
                                               {
                                                 type: 'md5',
                                                 digest: '2b9498107f73ff827e718d5c743f8802'
                                               }
                                             ],
                                             access: {
                                               view: 'dark',
                                               download: 'none'
                                             },
                                             administrative: {
                                               sdrPreserve: true,
                                               shelve: false,
                                               publish: false
                                             }
                                           }
                                         ]
                                       }
                                     }
                                   ],
                                   isMemberOf: [collection_druid]
                                 }),
      lock
    )
  end
  let(:collection_druid) { 'druid:bc778pm9866' }
  let(:reason) { 'No longer needed' }
  let(:sunetid) { 'awesome_po' }
  let(:apo_object) { build(:admin_policy, id: Settings.graveyard_admin_policy.druid) }
  let(:collection_object) { build(:collection, id: collection_druid) }
  let(:lock) { 'druid:hj185xx2222=4=2' }

  describe '.decommission' do
    subject(:decommission) do
      described_class.decommission(cocina_object:, reason:, sunetid:)
    end

    let!(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: druid, version: 1)
    end
    let(:decommissioned_cocina_object) do
      Cocina::Models.with_metadata(
        build(:dro, id: druid).new(access: { view: 'dark' },
                                   structural: {
                                     contains: [],
                                     isMemberOf: [collection_druid]
                                   },
                                   administrative: { hasAdminPolicy: apo_object.externalIdentifier }),
        updated_lock,
        created:,
        modified:
      )
    end
    let(:updated_lock) { 'druid:hj185xx2222=5=3' }
    let(:created) { repository_object.reload.created_at.utc }
    let(:modified) { repository_object.reload.updated_at.utc }

    before do
      create(:release_tag, druid:, released_to: 'Searchworks', what: 'self', who: 'bob', release: true,
                           created_at: 1.day.ago.iso8601)
      allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
      allow(CocinaObjectStore).to receive(:find).with(Settings.graveyard_admin_policy.druid).and_return(apo_object)
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection_object)
      allow(Indexer).to receive(:reindex_later)
      allow(VersionService).to receive(:open)
      allow(VersionService).to receive(:close)
      allow(Workflow::Service).to receive(:create)
      allow(ReleaseTagService).to receive(:create)
      allow(AdministrativeTags).to receive(:create)
    end

    it 'decommissions the object' do
      expect(decommission).to eq(decommissioned_cocina_object)

      expect(VersionService).to have_received(:open).with(cocina_object:,
                                                          description: "Decommissioned: #{reason}",
                                                          assume_accessioned: true,
                                                          opening_user_name: sunetid)

      expect(ReleaseTagService).to have_received(:create).with(tag: an_instance_of(Dor::ReleaseTag),
                                                               cocina_object:,
                                                               create_only: true)

      expect(AdministrativeTags).to have_received(:create).with(identifier: druid,
                                                                tags: ["Decommissioned : #{reason}"])

      expect(VersionService).to have_received(:close).with(druid:,
                                                           description: "Decommissioned: #{reason}",
                                                           user_name: sunetid,
                                                           version: cocina_object.version)

      expect(Indexer).to have_received(:reindex_later).with(druid:)
      expect(Workflow::Service).to have_received(:create).with(workflow_name: 'releaseWF', druid:,
                                                               version: cocina_object.version)
    end
  end
end
