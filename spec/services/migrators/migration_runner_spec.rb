# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MigrationRunner do
  describe '.migrate_druid_list' do
    subject(:results) do
      described_class.migrate_druid_list(migrator_class:, mode:, druids_slice:)
    end

    let(:repository_object1) { create(:repository_object, :with_repository_object_version) }
    let(:repository_object2) { create(:repository_object, :with_repository_object_version) }
    let(:druids_slice) { [repository_object1.external_identifier, repository_object2.external_identifier] }
    let(:migrator_class) { Migrators::Exemplar }
    let(:mode) { :dryrun }

    let(:runner1) do
      instance_double(described_class,
                      call: [described_class::Result.new, described_class::Result.new])
    end
    let(:runner2) { instance_double(described_class, call: [described_class::Result.new]) }

    before do
      allow(described_class).to receive(:new)
        .with(migrator_class:, repository_object: repository_object1, mode:).and_return(runner1)
      allow(described_class).to receive(:new)
        .with(migrator_class:, repository_object: repository_object2, mode:).and_return(runner2)
    end

    it 'returns the results from calling the migration runners' do
      expect(results.size).to eq 3
      expect(results.first).to be_a described_class::Result
    end
  end

  describe '#call' do
    subject(:results) { described_class.new(migrator_class:, repository_object:, mode:).call }

    let(:repository_object) do
      # This repository object will have 3 versions, each with a unique label:
      # version 1
      # version 2 (last closed)
      # version 3 (opened and head)
      create(:repository_object, :with_repository_object_version).tap do |repository_object|
        repository_object.head_version.update!(label: 'version 1')
        # First version is open. Close it.
        repository_object.close_version!(description: 'first version')
        # Open a second version.
        repository_object.open_version!(description: 'second version')
        repository_object.head_version.update!(label: 'version 2')
        # Close it and open a third version.
        repository_object.close_version!
        repository_object.open_version!(description: 'third version')
        repository_object.head_version.update!(label: 'version 3')
      end
    end
    let(:druid) { repository_object.external_identifier }
    let(:mode) { :migrate }
    let(:version_service) { instance_double(VersionService, close: nil, open: nil, ensure_openable!: nil, open?: true) }

    before do
      allow(VersionService).to receive(:new).and_return(version_service)
      allow(Publish::MetadataTransferService).to receive(:publish)
      allow(UpdateObjectService).to receive(:update)
    end

    context 'when migration strategy is commit' do
      context 'when some versions are changed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated" unless model_hash['version'] == 2
                model_hash
              end
            end
          )
        end

        it 'commits the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end

      context 'when no versions are changed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, status: 'UNCHANGED')
          )

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end
    end

    context 'when migration strategy is cocina_update' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              model_hash['label'] = "#{model_hash['label']} migrated"
              model_hash
            end

            def self.migration_strategy
              :cocina_update
            end

            def self.version_description
              'test migration'
            end
          end
        )
      end

      context 'when the object is open' do
        it 'calls UpdateObjectService with the migrated cocina object and closes the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )

          # Changes aren't persisted.
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'

          expect(version_service).not_to have_received(:open)
          expect(UpdateObjectService).to have_received(:update) do |args|
            expect(args[:cocina_object]).to be_an_instance_of(Cocina::Models::DROWithMetadata)
            expect(args[:cocina_object].label).to eq 'version 3 migrated'
            expect(args[:skip_open_check]).to be true
          end
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end

      context 'when the object is closed' do
        before do
          repository_object.close_version!
          allow(version_service).to receive(:open?).and_return(false)
        end

        it 'opens a new version, calls UpdateObjectService with the migrated cocina object, and closes the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 4, status: 'MIGRATED')
          )

          # Changes aren't persisted.
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'

          expect(VersionService).to have_received(:new)
            .with(druid:, version: 3, repository_object: repository_object).at_least(:once)

          expect(version_service).to have_received(:open).with(
            cocina_object: repository_object.head_version.to_cocina,
            description: 'test migration',
            assume_accessioned: false
          )

          expect(UpdateObjectService).to have_received(:update) do |args|
            expect(args[:cocina_object]).to be_an_instance_of(Cocina::Models::DROWithMetadata)
            expect(args[:cocina_object].version).to eq 4
            expect(args[:cocina_object].label).to eq 'version 3 migrated'
            expect(args[:skip_open_check]).to be true
          end

          expect(version_service).to have_received(:close)
            .with(description: nil, user_name: nil,
                  start_accession: true, user_version_mode: :update_if_existing, accession_args: { lane_id: 'low' })
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end

      context 'when the object is not changed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash
              end

              def self.migration_strategy
                :cocina_update
              end
            end
          )
        end

        it 'does not update the object or close the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, status: 'UNCHANGED')
          )

          expect(version_service).not_to have_received(:open)
          expect(UpdateObjectService).not_to have_received(:update)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end
    end

    context 'when migration strategy is commit_with_version' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              model_hash['label'] = "#{model_hash['label']} migrated" unless model_hash['version'] == 2
              model_hash
            end

            def self.migration_strategy
              :commit_with_version
            end

            def self.version_description
              'test migration'
            end
          end
        )
      end

      context 'when object is open and some versions are changed' do
        it 'commits the changes and closes the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end

      context 'when object is closed and some versions are changed' do
        # Stash this away beforen it is changed by migration.
        let!(:cocina_object_for_opening) { repository_object.head_version.to_cocina }

        before do
          repository_object.close_version!
          allow(version_service).to receive(:open?).and_return(false)
          allow(version_service).to receive(:open) do |_args|
            repository_object.open_version!(description: 'test migration')
          end
        end

        it 'commits the changes and opens and closes the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 4, status: 'MIGRATED')
          )
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'
          expect(repository_object.versions.find_by(version: 4).label).to eq 'version 3 migrated'

          expect(version_service).to have_received(:open).with(
            cocina_object: cocina_object_for_opening,
            description: 'test migration',
            assume_accessioned: false
          )
          expect(version_service).to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end

      context 'when no versions are changed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash
              end

              def self.migration_strategy
                :commit_with_version
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, status: 'UNCHANGED')
          )

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end
    end

    context 'when migration strategy is commit_with_publish' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              model_hash['label'] = "#{model_hash['label']} migrated" unless model_hash['version'] == 2
              model_hash
            end

            def self.migration_strategy
              :commit_with_publish
            end

            def self.version_description
              'test migration'
            end
          end
        )
      end

      context 'when some versions are changed' do
        it 'commits the changes and closes the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )
          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).to have_received(:publish).with(druid:)
        end
      end

      context 'when no versions are changed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash
              end

              def self.migration_strategy
                :commit_with_publish
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, status: 'UNCHANGED')
          )

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end
    end

    context 'when allow_invalid? is true' do
      context 'when there is a validation error in version other than opened or last closed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['identification'].delete('sourceId') if model_hash['version'] == 1
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end

              def self.allow_invalid?
                true
              end
            end
          )
        end

        it 'commits the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 2, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2 migrated'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'

          expect { repository_object.reload.versions.find_by(version: 1).to_cocina }.to raise_error(Cocina::Models::ValidationError)
        end
      end

      context 'when there is a validation error in opened version' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash['identification'].delete('sourceId') if model_hash['version'] == 3
                model_hash
              end

              def self.allow_invalid?
                true
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 3, status: 'INVALID', exception: /When validating DRO/)
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'
        end
      end

      context 'when there is a validation error in last closed version' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash['identification'].delete('sourceId') if model_hash['version'] == 2
                model_hash
              end

              def self.allow_invalid?
                true
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 2, status: 'INVALID', exception: /When validating DRO/)
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'
        end
      end
    end

    context 'when allow_invalid? is false' do
      context 'when there is a validation error' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['identification'].delete('sourceId') if model_hash['version'] == 1
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end
            end
          )
        end

        it 'does not commit the changes' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'INVALID',
                           exception: /When validating DRO/)
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'
        end
      end

      context 'when there is a previously invalid version' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end
            end
          )
        end

        let(:first_repository_object_version) { repository_object.versions.find_by(version: 1) }

        before do
          first_repository_object_version.update!(administrative: { 'hasAdminPolicy' => nil })
        end

        it 'commits the changes' do
          expect { first_repository_object_version.to_cocina }.to raise_error(Cocina::Models::ValidationError)

          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 2, status: 'MIGRATED'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2 migrated'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'
        end
      end
    end

    context 'when there is a version with no cocina' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              model_hash['label'] = "#{model_hash['label']} migrated"
              model_hash
            end
          end
        )
      end

      before do
        repository_object.versions.find_by(version: 2).update!(cocina_version: nil)
      end

      it 'skips that version' do
        expect(results.map(&:to_h)).to contain_exactly(
          hash_including(external_identifier: druid, version: 1, status: 'MIGRATED'),
          hash_including(external_identifier: druid, version: 3, status: 'MIGRATED')
        )
        expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1 migrated'
        expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
        expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3 migrated'
      end
    end

    context 'when a dryrun' do
      let(:mode) { :dryrun }

      context 'when migration strategy is cocina_update and object is closed' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end

              def self.migration_strategy
                :cocina_update
              end
            end
          )
        end

        before do
          repository_object.close_version!
          allow(version_service).to receive(:open?).and_return(false)
        end

        it 'does not call UpdateObjectService or close the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 4, status: 'MIGRATED (dry run)')
          )

          # The new version is not added..
          expect(repository_object.reload.versions.count).to eq 3

          expect(version_service).to have_received(:ensure_openable!)
          expect(version_service).not_to have_received(:open)
          expect(UpdateObjectService).not_to have_received(:update)
          expect(version_service).not_to have_received(:close)
        end
      end

      context 'when migration strategy is commit_with_version' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end

              def self.migration_strategy
                :commit_with_version
              end

              def self.version_description
                'test migration'
              end
            end
          )
        end

        it 'does not commit the changes or close the version' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED (dry run)'),
            hash_including(external_identifier: druid, version: 2, status: 'MIGRATED (dry run)'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED (dry run)')
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'

          expect(version_service).not_to have_received(:open)
          expect(version_service).not_to have_received(:close)
        end
      end

      context 'when commit strategy is commit_with_publish' do
        let(:migrator_class) do
          stub_const(
            'Migrators::TestMigrator',
            Class.new(Migrators::Base) do
              def migrate
                model_hash['label'] = "#{model_hash['label']} migrated"
                model_hash
              end

              def self.migration_strategy
                :commit_with_publish
              end
            end
          )
        end

        it 'does not commit the changes or publish' do
          expect(results.map(&:to_h)).to contain_exactly(
            hash_including(external_identifier: druid, version: 1, status: 'MIGRATED (dry run)'),
            hash_including(external_identifier: druid, version: 2, status: 'MIGRATED (dry run)'),
            hash_including(external_identifier: druid, version: 3, status: 'MIGRATED (dry run)')
          )

          expect(repository_object.reload.versions.find_by(version: 1).label).to eq 'version 1'
          expect(repository_object.versions.find_by(version: 2).label).to eq 'version 2'
          expect(repository_object.versions.find_by(version: 3).label).to eq 'version 3'

          expect(Publish::MetadataTransferService).not_to have_received(:publish)
        end
      end
    end

    context 'when there is an error in the migrator' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              raise 'Something went wrong during migration' if model_hash['version'] == 2

              model_hash
            end
          end
        )
      end

      it 'returns a result with status ERROR and the exception message' do
        expect(results.map(&:to_h)).to contain_exactly(
          hash_including(external_identifier: druid, version: 2, status: 'ERROR',
                         exception: 'Something went wrong during migration')
        )
      end
    end

    context 'when there is an error in the runner' do
      let(:migrator_class) do
        stub_const(
          'Migrators::TestMigrator',
          Class.new(Migrators::Base) do
            def migrate
              model_hash['label'] = "#{model_hash['label']} migrated"
              model_hash
            end

            def self.migration_strategy
              :cocina_update
            end
          end
        )
      end

      before do
        allow(UpdateObjectService).to receive(:update).and_raise('Something went wrong in the runner')
      end

      it 'returns a result with status ERROR and the exception message' do
        expect(results.map(&:to_h)).to contain_exactly(
          hash_including(external_identifier: druid, version: nil, status: 'ERROR',
                         exception: 'Something went wrong in the runner')
        )
      end
    end
  end
end
