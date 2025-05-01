# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MoveDigitalSerials do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object) { repository_object_version.repository_object }
  let(:repository_object_version) { build(:repository_object_version, :with_repository_object, identification:) }
  let(:identification) { { catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a1234', refresh: 'false' }] } }

  describe '#migrate?' do
    subject { migrator.migrate? }

    it { is_expected.to be true }
  end

  describe 'migrate' do
    it 'populates the catalogLink partLabel and sortKey' do
      migrator.migrate
      expect(repository_object.versions.first.identification).to eq({ catalogLinks: [{ catalog: 'folio',
                                                                                       catalogRecordId: 'a1234', refresh: 'false', partLabel: '', sortKey: '' }] })
    end

    it 'removes the description title parts' do
    end

    it 'removes the description note' do
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
