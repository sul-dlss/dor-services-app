# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::AddLaneHrid do
  subject(:migrator) { described_class.new(obj) }

  let(:obj) { create(:ar_dro) }

  describe '.druids' do
    it 'returns an array' do
      expect(described_class.druids).to include 'druid:bc836hv7886'
    end
  end

  describe '#migrate?' do
    context 'when a matching druid and no hrid' do
      let(:obj) { create(:ar_dro, external_identifier: 'druid:bc836hv7886') }

      it 'returns true' do
        expect(migrator.migrate?).to be true
      end
    end

    context 'when a matching druid and has hrid' do
      let(:obj) do
        create(:ar_dro, external_identifier: 'druid:bc836hv7886', identification:)
      end

      let(:identification) do
        {
          sourceId: 'sul:1234',
          catalogLinks: [
            { catalog: 'folio', catalogRecordId: 'L123456' }
          ]
        }
      end

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end

    context 'when a non-matching druid' do
      let(:obj) do
        create(:ar_dro, external_identifier: 'druid:bc836hv7887')
      end

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    context 'when no existing catalog links' do
      let(:obj) { create(:ar_dro, external_identifier: 'druid:bc836hv7886', identification:) }

      let(:identification) do
        {
          sourceId: 'sul:1234',
          catalogLinks: [
            { 'catalog' => 'symphony', 'catalogRecordId' => '123456' }
          ]
        }
      end

      it 'adds catalog link' do
        migrator.migrate
        expect(obj.identification['catalogLinks']).to eq [
          { 'catalog' => 'symphony', 'catalogRecordId' => '123456' },
          { 'catalog' => 'folio', 'catalogRecordId' => 'L123456', 'refresh' => true }
        ]
      end
    end

    context 'when existing catalog links' do
      let(:obj) { create(:ar_dro, external_identifier: 'druid:bc836hv7886') }

      it 'appends catalog link' do
        migrator.migrate
        expect(obj.identification['catalogLinks']).to eq [{ 'catalog' => 'folio', 'catalogRecordId' => 'L123456', 'refresh' => true }]
      end
    end
  end

  describe '#publish?' do
    it 'returns false' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false' do
      expect(migrator.version?).to be true
    end
  end

  describe '#version_description' do
    it 'returns description' do
      expect(migrator.version_description).to eq 'Add Lane HRID'
    end
  end
end
