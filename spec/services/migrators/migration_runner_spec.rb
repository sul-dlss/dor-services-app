# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MigrationRunner do
  let!(:objects_to_migrate) do
    [
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734'),
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:rd069rk9728')
    ]
  end
  let(:migrated_druids) { %w[druid:bc177tq6734 druid:rd069rk9728] }

  let!(:objects_to_ignore) do
    create_list(:repository_object, 2, :with_repository_object_version)
  end
  let(:ignored_druids) { objects_to_ignore.map(&:external_identifier) }

  let(:migrator_class) { Migrators::Exemplar }

  before do
    create(:repository_object, :admin_policy, :with_repository_object_version, external_identifier: 'druid:hy787xj5878')
  end

  describe '.druids_for' do
    let(:sample) { nil }

    it 'returns the druids it cares about' do
      expect(described_class.druids_for(migrator_class:, sample:)).to eq(migrated_druids)
    end
  end

  describe '.migrate_druid_list' do
    let(:mode) { :commit }
    let(:druids_slice) { described_class.druids_for(migrator_class:, sample: nil) }

    it 'migrates exactly the objects it should' do
      expect(objects_to_migrate.first.head_version.label).not_to include('migrated')
      expect(objects_to_migrate.second.head_version.label).not_to include('migrated')
      expect(objects_to_ignore.first.head_version.label).not_to include('migrated')
      expect(objects_to_ignore.second.head_version.label).not_to include('migrated')

      described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)

      expect(
        RepositoryObject.find_by(external_identifier: migrated_druids[0]).head_version.label
      ).to include('migrated')
      expect(
        RepositoryObject.find_by(external_identifier: migrated_druids[1]).head_version.label
      ).to include('migrated')
      expect(
        RepositoryObject.find_by(external_identifier: ignored_druids[0]).head_version.label
      ).not_to include('migrated')
      expect(
        RepositoryObject.find_by(external_identifier: ignored_druids[1]).head_version.label
      ).not_to include('migrated')
    end

    context 'with migrate mode' do
      let(:mode) { :migrate }

      before do
        allow(Publish::MetadataTransferService).to receive(:publish)
      end

      it 'migrates exactly the objects it should' do
        expect(objects_to_migrate.first.head_version.label).not_to include('migrated')
        expect(objects_to_migrate.second.head_version.label).not_to include('migrated')
        expect(objects_to_ignore.first.head_version.label).not_to include('migrated')
        expect(objects_to_ignore.second.head_version.label).not_to include('migrated')

        described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)

        expect(
          RepositoryObject.find_by(external_identifier: migrated_druids[0]).head_version.label
        ).to include('migrated')
        expect(
          RepositoryObject.find_by(external_identifier: migrated_druids[1]).head_version.label
        ).to include('migrated')
        expect(
          RepositoryObject.find_by(external_identifier: ignored_druids[0]).head_version.label
        ).not_to include('migrated')
        expect(
          RepositoryObject.find_by(external_identifier: ignored_druids[1]).head_version.label
        ).not_to include('migrated')
      end

      it 'does not publish if the migrator says not to' do
        described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)
        expect(Publish::MetadataTransferService).not_to have_received(:publish)
      end

      context 'when the migrator says to publish' do
        let(:migrator_class) { Migrators::ExemplarWithPublish }

        it 'publishes the object' do
          described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)
          migrated_druids.each { |druid| expect(Publish::MetadataTransferService).to have_received(:publish).with(druid:) }
        end
      end
    end
  end
end
