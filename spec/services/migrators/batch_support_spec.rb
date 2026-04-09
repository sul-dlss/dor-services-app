# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::BatchSupport do
  describe '.batch_descriptors' do
    let(:repository_objects) do
      create_list(:repository_object, 5)
    end
    let!(:ids) { repository_objects.map(&:id) }

    it 'returns [0, count] for the first (and only) batch' do
      expect(described_class.batch_descriptors(batch_size: RepositoryObject.count))
        .to contain_exactly([0, RepositoryObject.count])
    end

    context 'with a sample size' do
      it 'limits total druids to the sample size' do
        expect(described_class.batch_descriptors(sample: 2, batch_size: RepositoryObject.count))
          .to contain_exactly([0, 2])
      end
    end

    context 'when batch_size is provided' do
      it 'uses the provided batch_size instead of the default' do
        expect(described_class.batch_descriptors(batch_size: 2))
          .to contain_exactly([0, 2], [ids[1], 2], [ids[3], 1])
      end
    end
  end

  describe '.druids_for_batch' do
    let(:repository_objects) do
      create_list(:repository_object, 5)
    end
    let!(:druids) { repository_objects.map(&:external_identifier) }

    let(:batch_descriptors) { described_class.batch_descriptors(sample: nil, batch_size: 2) }

    it 'returns druids from the DB for the given batch descriptor' do
      expect(described_class.druids_for_batch(batch_descriptor: batch_descriptors.first)).to eq(druids[0..1])
      expect(described_class.druids_for_batch(batch_descriptor: batch_descriptors.second)).to eq(druids[2..3])
      expect(described_class.druids_for_batch(batch_descriptor: batch_descriptors.third)).to eq(druids[4..4])
    end
  end

  describe '.slices_for_file' do
    let(:file) { Tempfile.new }
    let(:druids) { Array.new(5) { generate(:unique_druid) } }

    before do
      file.write(druids.join("\n"))
      file.rewind
    end

    after do
      file.close
      file.unlink
    end

    it 'yields batches of druids from the given file' do
      expect(described_class.slices_for_file(file: file.path, batch_size: 2).to_a)
        .to eq([druids[0..1], druids[2..3], druids[4..4]])
    end

    context 'with a sample size' do
      it 'limits total druids to the sample size' do
        expect(described_class.slices_for_file(file: file.path, batch_size: 2, sample: 3).to_a)
          .to eq([druids[0..1], druids[2..2]])
      end
    end
  end
end
