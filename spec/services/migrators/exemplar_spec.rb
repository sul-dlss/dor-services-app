# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::Exemplar do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object) { create(:repository_object, :with_repository_object_version) }

  describe '.druids' do
    it 'returns an array' do
      expect(described_class.druids).to be_an Array
    end
  end

  describe '#migrate?' do
    context 'when a matching druid' do
      let(:repository_object) do
        create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
      end

      it 'returns true' do
        expect(migrator.migrate?).to be true
      end
    end

    context 'when not a matching druid' do
      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    let(:repository_object_version) { build(:repository_object_version, label: 'Test DRO - migrated XYZ') }
    let(:repository_object) { create(:repository_object, :with_repository_object_version, repository_object_version:) }

    it 'updates label and title' do
      migrator.migrate
      repository_object.save
      repository_object.reload
      expect(repository_object.head_version.label).to match(/Test DRO - migrated \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      expect(repository_object.head_version.description['title'].first['value'])
        .to match(/Test DRO - migrated \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end
  end

  describe '#publish?' do
    it 'returns false as migrated SDR objects should not be published' do
      expect(migrator.publish?).to be false
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
