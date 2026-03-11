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

  describe '.druids_count_for' do
    let(:sample) { nil }

    context 'when the migrator class specifies druids' do
      it 'returns the count of those druids' do
        expect(described_class.druids_count_for(migrator_class:, sample:)).to eq(migrated_druids.size)
      end
    end

    context 'when the migrator class does not specify druids' do
      let(:migrator_class) do
        Class.new(Migrators::Base) do
          def self.druids = nil
        end
      end

      it 'returns the total count of all repository objects' do
        expect(described_class.druids_count_for(migrator_class:, sample:)).to eq(RepositoryObject.count)
      end

      context 'with a sample size' do
        let(:sample) { 1 }

        it 'limits to the sample size' do
          expect(described_class.druids_count_for(migrator_class:, sample:)).to eq(1)
        end
      end
    end
  end

  describe '.druids_for_batch' do
    let(:sample) { nil }

    context 'when the migrator class specifies druids' do
      it 'returns the correct batch of druids' do
        expect(described_class.druids_for_batch(migrator_class:, sample:, batch_index: 0)).to eq(migrated_druids)
      end

      it 'returns an empty array for an out-of-range batch index' do
        expect(described_class.druids_for_batch(migrator_class:, sample:, batch_index: 999)).to eq([])
      end
    end

    context 'when the migrator class does not specify druids' do
      let(:migrator_class) do
        Class.new(Migrators::Base) do
          def self.druids = nil
        end
      end

      it 'returns druids from the DB for the given batch index' do
        all_druids = (migrated_druids + ignored_druids + ['druid:hy787xj5878']).sort
        batch = described_class.druids_for_batch(migrator_class:, sample:, batch_index: 0)
        expect(batch).not_to be_empty
        expect(batch).to all(be_in(all_druids))
      end

      context 'with a sample size' do
        let(:sample) { 2 }

        it 'limits total results to the sample size' do
          batch = described_class.druids_for_batch(migrator_class:, sample:, batch_index: 0)
          expect(batch.size).to eq(2)
        end
      end
    end
  end

  describe '.migrate_druid_list' do
    let(:mode) { :commit }
    let(:druids_slice) { described_class.druids_for_batch(migrator_class:, sample: nil, batch_index: 0) }

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

      context 'when the migration creates invalid data' do
        let(:migrator_class) { Migrators::ExemplarWithLabelRemoval }

        before do
          # in migrate mode, when not not using a migrator that says to open/close versions as part of the migration,
          # the objects must already be open for update, or else UpdateObjectService.update will throw an error.
          allow(Publish::MetadataTransferService).to receive(:publish)
          objects_to_migrate.each do |obj|
            cocina_object = obj.head_version.to_cocina_with_metadata
            VersionService.open(cocina_object:, description: 'migration test', from_version: obj.head_version.version)
          end
        end

        it 'validates (and returns an error for each migration failure) without saving the invalid data' do
          expect(objects_to_migrate.first.head_version.label).not_to be_blank
          expect(objects_to_migrate.second.head_version.label).not_to be_blank
          expect(objects_to_ignore.first.head_version.label).not_to be_blank
          expect(objects_to_ignore.second.head_version.label).not_to be_blank

          migration_results = described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)
          expect(migration_results.map do |result|
            [result[:obj].external_identifier, result[:status], result[:exception].to_s]
          end).to include(
            ['druid:bc177tq6734', 'ERROR', /missing required properties: label/],
            ['druid:rd069rk9728', 'ERROR', /missing required properties: label/]
          )
          expect(migration_results.size).to eq 2

          expect(objects_to_migrate.first.head_version.label).not_to be_blank
          expect(objects_to_migrate.second.head_version.label).not_to be_blank
          expect(objects_to_ignore.first.head_version.label).not_to be_blank
          expect(objects_to_ignore.second.head_version.label).not_to be_blank
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

    context 'when using dryrun mode' do
      let(:mode) { :dryrun }

      context 'when an error raised during migration' do
        let(:migrator_class) { Migrators::Exemplar }
        let(:migrator_instance) do
          instance_double(migrator_class, migrate?: true, version?: false, migrate: 'Migrated label')
        end

        before do
          allow(migrator_class).to receive(:new).and_return(migrator_instance)
          allow(migrator_instance).to receive(:updated_head_version_cocina_object).and_raise(
            StandardError, 'this is an error from the migrator'
          )
        end

        it 'returns an error status and exception for the migrated objects' do
          migration_results = described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)
          expect(migration_results.map do |result|
            [result[:obj].external_identifier, result[:status], result[:exception].to_s]
          end).to include(
            ['druid:bc177tq6734', 'ERROR', /this is an error from the migrator/],
            ['druid:rd069rk9728', 'ERROR', /this is an error from the migrator/]
          )
          expect(migration_results.size).to eq 2
        end
      end
    end
  end
end
