# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::Folio do
  subject(:migrator) { described_class.new(ar_cocina_object) }

  let(:ar_cocina_object) { create(:ar_dro) }

  let(:unmigrated_identification) do
    {
      sourceId: 'sul:1234',
      catalogLinks: [
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
    }
  end

  let(:migrated_identification) do
    {
      sourceId: 'sul:1234',
      catalogLinks: [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
    }
  end

  describe '.druids' do
    it 'returns nil' do
      expect(described_class.druids).to be_nil
    end
  end

  describe '#migrate?' do
    context 'when an AdminPolicy' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end

    context 'when no catalog links' do
      let(:ar_cocina_object) { create(:ar_dro, identification: { sourceId: 'sul:1234' }) }

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end

    context 'when not yet migrated' do
      let(:ar_cocina_object) { create(:ar_collection, identification: unmigrated_identification) }

      it 'returns true' do
        expect(migrator.migrate?).to be true
      end
    end

    context 'when migrated' do
      let(:ar_cocina_object) { create(:ar_collection, identification: migrated_identification) }

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    let(:ar_cocina_object) { create(:ar_dro, identification: unmigrated_identification) }

    it 'adds Folio catalog links' do
      migrator.migrate
      expect(ar_cocina_object.identification).to match migrated_identification.with_indifferent_access
    end
  end

  describe '#publish?' do
    it 'returns false' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false' do
      expect(migrator.version?).to be false
    end
  end
end
