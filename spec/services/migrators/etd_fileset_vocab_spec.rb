# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::EtdFilesetVocab do
  subject(:migrator) { described_class.new(ar_cocina_object) }

  let(:non_matching_druid) { 'druid:bc123df4567' }
  let(:matching_druid) { 'druid:bb007hx5508' }
  let(:collection_druid) { 'druid:kv784nx1963' }
  let(:original_pdf_name) { 'my_thesis.pdf' }
  let(:main_original_fileset) do
    {
      type: 'https://cocina.sul.stanford.edu/models/resources/main-original',
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/#{matching_druid}-main",
      label: 'Body of Dissertation (as submitted)',
      version: 3,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{original_pdf_name}",
            label: original_pdf_name,
            filename: original_pdf_name,
            size: 666,
            version: 3,
            hasMimeType: 'application/pdf',
            hasMessageDigests: [
              {
                type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
              }, {
                type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
              }
            ],
            access: { view: 'world', download: 'world' },
            administrative: { publish: false, sdrPreserve: true, shelve: true }
          }
        ]
      }
    }
  end
  let(:augmented_pdf_name) { 'mythesis-augmented.pdf' }
  # NOTE: see https://argo.stanford.edu/items/druid:bb007hx5508.json - the file externalIdentifier is repeated
  let(:main_augmented_fileset) do
    {
      type: 'https://cocina.sul.stanford.edu/models/resources/main-augmented',
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/#{matching_druid}-main",
      label: 'Body of Dissertation',
      version: 1,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{matching_druid}-main/#{augmented_pdf_name}",
            label: augmented_pdf_name,
            filename: augmented_pdf_name,
            size: 666,
            version: 1,
            hasMimeType: 'application/pdf',
            hasMessageDigests: [
              {
                type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
              }, {
                type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
              }
            ],
            access: { view: 'world', download: 'world' },
            administrative: { publish: false, sdrPreserve: true, shelve: true }
          }
        ]
      }
    }
  end
  let(:permissions_file_name) { 'permissions.txt' }
  let(:permissions_fileset) do
    {
      type: 'https://cocina.sul.stanford.edu/models/resources/permissions',
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/#{matching_druid}-permissions",
      label: 'Body of Dissertation',
      version: 1,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{matching_druid}-permissions/#{permissions_file_name}",
            label: permissions_file_name,
            filename: permissions_file_name,
            size: 666,
            version: 1,
            hasMimeType: 'text/plain',
            hasMessageDigests: [
              {
                type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
              }, {
                type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
              }
            ],
            access: { view: 'world', download: 'world' },
            administrative: { publish: false, sdrPreserve: true, shelve: true }
          }
        ]
      }
    }
  end
  let(:supplement_file_name) { 'supplement.txt' }
  let(:supplement_fileset) do
    {
      type: 'https://cocina.sul.stanford.edu/models/resources/supplement',
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/#{matching_druid}-supplement",
      label: 'Body of Dissertation',
      version: 1,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{matching_druid}-supplement/#{supplement_file_name}",
            label: supplement_file_name,
            filename: supplement_file_name,
            size: 666,
            version: 1,
            hasMimeType: 'text/plain',
            hasMessageDigests: [
              {
                type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
              }, {
                type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
              }
            ],
            access: { view: 'world', download: 'world' },
            administrative: { publish: false, sdrPreserve: true, shelve: true }
          }
        ]
      }
    }
  end
  let(:image_filename) { 'image.jp2' }
  let(:image_fileset) do
    {
      type: Cocina::Models::FileSetType.image,
      externalIdentifier: "https://cocina.sul.stanford.edu/fileSet/#{matching_druid}-#{image_filename}",
      label: 'Body of Dissertation',
      version: 1,
      structural: {
        contains: [
          {
            type: Cocina::Models::ObjectType.file,
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{matching_druid}-supplement/#{supplement_file_name}",
            label: supplement_file_name,
            filename: supplement_file_name,
            size: 666,
            version: 1,
            hasMimeType: 'image/jp2',
            hasMessageDigests: [
              {
                type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
              }, {
                type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
              }
            ],
            access: { view: 'world', download: 'world' },
            administrative: { publish: true, sdrPreserve: true, shelve: true }
          }
        ]
      }
    }
  end
  let(:structural_all_etd_types_only) do
    {
      contains:
        [
          main_original_fileset,
          main_augmented_fileset,
          permissons_fileset,
          supplement_fileset
        ],
      hasMemberOrders: [],
      isMemberOf: [collection_druid]
    }
  end
  let(:structural_etd_and_non) do
    {
      contains:
        [
          main_original_fileset,
          main_augmented_fileset,
          # NOTE: this should never happen, but a good test case
          image_fileset
        ],
      hasMemberOrders: [],
      isMemberOf: [collection_druid]
    }
  end
  let(:structural_no_match) do
    {
      contains:
        [
          image_fileset
        ],
      hasMemberOrders: [],
      isMemberOf: [collection_druid]
    }
  end

  let(:ar_cocina_object) { create(:ar_dro, external_identifier: non_matching_druid) }

  describe '.druids' do
    it 'returns an array of size 8225' do
      expect(described_class.druids).to be_an Array
      expect(described_class.druids.size).to eq(8225)
    end
  end

  describe '#migrate?' do
    context 'when a matching druid' do
      context 'when cocina has a matching fileset type' do
        let(:ar_cocina_object) { create(:ar_dro, external_identifier: matching_druid, structural: structural_etd_and_non) }

        it 'returns true' do
          expect(migrator.migrate?).to be true
        end
      end

      context 'when cocina has no matching fileset type' do
        let(:ar_cocina_object) { create(:ar_dro, external_identifier: matching_druid, structural: structural_no_match) }

        it 'returns false' do
          expect(migrator.migrate?).to be false
        end
      end
    end

    context 'when not a matching druid' do
      let(:ar_cocina_object) { create(:ar_dro, external_identifier: non_matching_druid) }

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    let(:ar_cocina_object) { create(:ar_dro, external_identifier: matching_druid, structural: structural_etd) }

    context 'when at least one fileset type matches' do
      let(:structural_etd) do
        {
          contains:
            [
              main_original_fileset,
              main_augmented_fileset
            ],
          hasMemberOrders: [],
          isMemberOf: [collection_druid]
        }
      end

      it 'migrates the matching fileset types to Cocina::Models::FileSetType.file' do
        migrator.migrate
        expect(ar_cocina_object.structural['contains'].first['type']).to eq 'https://cocina.sul.stanford.edu/models/resources/file'
        expect(ar_cocina_object.structural['contains'].last['type']).to eq Cocina::Models::FileSetType.file
      end

      context 'when fileset label is already present' do
        it 'does not change the label' do
          first_label_before = ar_cocina_object.structural['contains'].first['label']
          last_label_before = ar_cocina_object.structural['contains'].last['label']
          expect(first_label_before).to be_present
          expect(last_label_before).to be_present
          migrator.migrate
          expect(ar_cocina_object.structural['contains'].first['label']).to eq first_label_before
          expect(ar_cocina_object.structural['contains'].last['label']).to eq last_label_before
        end
      end

      context 'when fileset label is blank' do
        let(:structural_etd) do
          {
            contains:
              [
                fileset_blank_label
              ],
            hasMemberOrders: [],
            isMemberOf: [collection_druid]
          }
        end

        before do
          migrator.migrate
        end

        context 'when main-original fileset' do
          let(:fileset_blank_label) { main_original_fileset.dup.tap { |fileset| fileset[:label] = '' } }

          it 'main-original fileset gets "Body of dissertation (as submitted)"' do
            expect(ar_cocina_object.structural['contains'].first['label']).to eq 'Body of dissertation (as submitted)'
          end
        end

        context 'when main-augmented fileset' do
          let(:fileset_blank_label) { main_augmented_fileset.dup.tap { |fileset| fileset[:label] = '' } }

          it 'main-augmented fileset gets "Body of dissertation"' do
            expect(ar_cocina_object.structural['contains'].first['label']).to eq 'Body of dissertation'
          end
        end

        context 'when permissions fileset' do
          let(:fileset_blank_label) { permissions_fileset.dup.tap { |fileset| fileset[:label] = '' } }

          it 'permissions fileset gets "permission file"' do
            expect(ar_cocina_object.structural['contains'].first['label']).to eq 'permission file'
          end
        end

        context 'when supplement fileset' do
          let(:fileset_blank_label) { supplement_fileset.dup.tap { |fileset| fileset[:label] = '' } }

          it 'supplement fileset gets "supplemental file"' do
            expect(ar_cocina_object.structural['contains'].first['label']).to eq 'supplemental file'
          end
        end
      end

      context 'when some fileset types match' do
        let(:ar_cocina_object) { create(:ar_dro, external_identifier: matching_druid, structural: structural_etd_and_non) }

        before do
          migrator.migrate
        end

        it 'migrates all matching fileset types' do
          expect(ar_cocina_object.structural['contains'].first).not_to eq main_original_fileset
          expect(ar_cocina_object.structural['contains'].second).not_to eq main_augmented_fileset
        end

        it 'does not migrate non-matching fileset types' do
          expect(ar_cocina_object.structural['contains'].last.as_json).to eq image_fileset.as_json
        end
      end
    end
  end

  describe '#publish?' do
    it 'returns true as migrated SDR objects should be published' do
      expect(migrator.publish?).to be true
    end
  end

  describe '#version?' do
    it 'returns false as migrated SDR objects should not be versioned' do
      expect(migrator.version?).to be false
    end
  end

  describe '#version_description' do
    it 'raises an error as version? is never true' do
      expect { migrator.version_description }.to raise_error(NotImplementedError)
    end
  end
end
