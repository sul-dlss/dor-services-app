# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveReleaseTags do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object) { repository_object_version.repository_object }
  let(:repository_object_version) { build(:repository_object_version, :with_repository_object, administrative:) }
  let(:administrative) { { hasAdminPolicy: 'druid:hy787xj5878', releaseTags: [] } }

  describe '#migrate?' do
    subject { migrator.migrate? }

    it { is_expected.to be true }
  end

  describe 'migrate' do
    it 'removes releaseTags' do
      migrator.migrate
      expect(repository_object.versions.first.administrative).to eq({ 'hasAdminPolicy' => 'druid:hy787xj5878' })
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
