# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MigrationRunner do
  let!(:objects_to_migrate) do
    [
      create(:repository_object, :with_repository_object_version, :closed, external_identifier: 'druid:bc177tq6734'),
      create(:repository_object, :with_repository_object_version, :closed, external_identifier: 'druid:rd069rk9728')
    ]
  end
  let(:migrated_druids) { %w[druid:bc177tq6734 druid:rd069rk9728] }

  let!(:objects_to_ignore) do
    create_list(:repository_object, 2, :with_repository_object_version, :closed)
  end
  let(:ignored_druids) { objects_to_ignore.map(&:external_identifier) }

  let(:migrator_class) { Migrators::Exemplar }

  before do
    create(:repository_object, :admin_policy, :with_repository_object_version, :closed,
           external_identifier: 'druid:hy787xj5878')
    (migrated_druids + ignored_druids + ['druid:hy787xj5878']).each do |accessioned_druid|
      create(:workflow_step, druid: accessioned_druid, workflow: 'accessionWF', active_version: true,
                             process: 'end-accession', lifecycle: 'accessioned', status: 'completed')
      mock_pres_client = instance_double(Preservation::Client::Object, current_version: 1, ok_on_local_storage?: true)
      allow(Preservation::Client.objects).to receive(:object).with(accessioned_druid).and_return(mock_pres_client)
    end
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

    context 'when using migrate mode' do
      let(:mode) { :migrate }

      context 'when the migrator does not override Migrators::Base#version?' do
        before do
          # in migrate mode, when not not using a migrator that says to open/close versions as part of the migration,
          # the objects must already be open for update, or else UpdateObjectService.update will throw an error.
          allow(Publish::MetadataTransferService).to receive(:publish)
          objects_to_migrate.each do |obj|
            cocina_object = obj.head_version.to_cocina_with_metadata
            VersionService.open(cocina_object:, description: 'migration test', from_version: obj.head_version.version)
          end
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
      end

      describe 'publish?' do
        before do
          # in migrate mode, when not not using a migrator that says to open/close versions as part of the migration,
          # the objects must already be open for update, or else UpdateObjectService.update will throw an error.
          allow(Publish::MetadataTransferService).to receive(:publish)
          objects_to_migrate.each do |obj|
            cocina_object = obj.head_version.to_cocina_with_metadata
            VersionService.open(cocina_object:, description: 'migration test', from_version: obj.head_version.version)
          end
        end

        it 'does not publish if the migrator does not override Migrators::Base#publish?' do
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

      context 'when the migrator says to version' do
        let(:migrator_class) { Migrators::ExemplarWithVersioning }

        before do
          allow(Workflow::Service).to receive(:create)
        end

        it 'opens/closes exactly the objects it migrates' do
          expect { described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:) }.to(
            change { RepositoryObject.find_by(external_identifier: migrated_druids[0]).last_closed_version }
            .and(
              change { RepositoryObject.find_by(external_identifier: migrated_druids[1]).last_closed_version }
              .and(
                not_change { RepositoryObject.find_by(external_identifier: ignored_druids[0]).last_closed_version }
                .and(not_change { RepositoryObject.find_by(external_identifier: ignored_druids[1]).last_closed_version }) # rubocop:disable Layout/LineLength
              )
            )
          )
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

        it 'increments the version' do
          expect(objects_to_migrate.first.head_version.version).to eq 1
          expect(objects_to_migrate.second.head_version.version).to eq 1
          expect(objects_to_ignore.first.head_version.version).to eq 1
          expect(objects_to_ignore.second.head_version.version).to eq 1

          described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)

          expect(
            RepositoryObject.find_by(external_identifier: migrated_druids[0]).head_version.version
          ).to eq 2
          expect(
            RepositoryObject.find_by(external_identifier: migrated_druids[1]).head_version.version
          ).to eq 2

          expect(
            RepositoryObject.find_by(external_identifier: ignored_druids[0]).head_version.version
          ).to eq 1
          expect(
            RepositoryObject.find_by(external_identifier: ignored_druids[1]).head_version.version
          ).to eq 1
        end
      end
    end
  end
end
