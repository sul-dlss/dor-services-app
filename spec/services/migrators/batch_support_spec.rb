# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::BatchSupport do
  let(:migrated_druids) { Migrators::Exemplar::TEST_DRUIDS }

  let!(:objects_to_ignore) do
    create_list(:repository_object, 2, :with_repository_object_version, :closed)
  end
  let(:ignored_druids) { objects_to_ignore.map(&:external_identifier) }

  let(:migrator_class) { Migrators::Exemplar }

  before do
    # Objects to migrate
    create(:repository_object, :with_repository_object_version, :closed, external_identifier: migrated_druids.first)
    create(:repository_object, :with_repository_object_version, :closed, external_identifier: migrated_druids.second)

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

  describe '.batch_descriptors' do
    context 'when the migrator class specifies druids' do
      it 'returns one descriptor per batch with index and count' do
        descriptors = described_class.batch_descriptors(migrator_class:, sample: nil)
        expect(descriptors).to eq([[0, migrated_druids.size]])
      end

      context 'with a sample size' do
        it 'limits the descriptors to the sample' do
          descriptors = described_class.batch_descriptors(migrator_class:, sample: 1)
          expect(descriptors.sum(&:last)).to eq(1)
        end
      end
    end

    context 'when the migrator class does not specify druids' do
      let(:migrator_class) do
        Class.new(Migrators::Base) do
          def self.druids = nil
        end
      end

      it 'returns [0, count] for the first (and only) batch' do
        descriptors = described_class.batch_descriptors(migrator_class:, sample: nil)
        expect(descriptors.size).to eq(1)
        expect(descriptors.first.first).to eq(0) # after_id starts at 0
        expect(descriptors.first.last).to eq(RepositoryObject.count)
      end

      context 'with a sample size' do
        it 'limits total druids to the sample size' do
          descriptors = described_class.batch_descriptors(migrator_class:, sample: 2)
          expect(descriptors.sum(&:last)).to eq(2)
        end
      end

      context 'when batch_size is provided' do
        it 'uses the provided batch_size instead of the default' do
          descriptors = described_class.batch_descriptors(migrator_class:, sample: nil, batch_size: 2)

          expect(descriptors.map(&:last)).to eq([2, 2, 1])
          expect(descriptors.sum(&:last)).to eq(RepositoryObject.count)
        end
      end
    end
  end

  describe '.druids_for_batch' do
    context 'when the migrator class specifies druids' do
      it 'returns the correct batch of druids' do
        expect(described_class.druids_for_batch(migrator_class:,
                                                batch_descriptor: [0,
                                                                   migrated_druids.size])).to eq(migrated_druids)
      end

      it 'returns an empty array for an out-of-range batch index' do
        expect(described_class.druids_for_batch(migrator_class:,
                                                batch_descriptor: [999,
                                                                   described_class::BATCH_SIZE])).to eq([])
      end
    end

    context 'when the migrator class does not specify druids' do
      let(:migrator_class) do
        Class.new(Migrators::Base) do
          def self.druids = nil
        end
      end

      it 'returns druids from the DB for the given batch descriptor' do
        all_druids = (migrated_druids + ignored_druids + ['druid:hy787xj5878']).sort
        batch = described_class.druids_for_batch(migrator_class:, batch_descriptor: [0, described_class::BATCH_SIZE])
        expect(batch).not_to be_empty
        expect(batch).to all(be_in(all_druids))
      end

      context 'with a sample size' do
        it 'limits total results to the sample size' do
          batch = described_class.druids_for_batch(migrator_class:, batch_descriptor: [0, 2])
          expect(batch.size).to eq(2)
        end
      end
    end
  end
end
