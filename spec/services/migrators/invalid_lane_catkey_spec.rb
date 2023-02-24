# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::InvalidLaneCatkey do
  subject(:migrator) { described_class.new(obj) }

  let(:obj) { create(:ar_dro) }

  describe '.druids' do
    it 'returns an array' do
      expect(described_class.druids).to include 'druid:bc640yg4341'
    end
  end

  describe '#migrate?' do
    context 'when a matching druid and no catalog links' do
      let(:obj) { create(:ar_dro, external_identifier: 'druid:bc640yg4341') }

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end

    context 'when a matching druid and previous symphony' do
      let(:obj) do
        create(:ar_dro, external_identifier: 'druid:bc836hv7886', identification:)
      end

      let(:identification) do
        {
          sourceId: 'sul:1234',
          catalogLinks: [
            { catalog: 'previous symphony', catalogRecordId: '10065784' }
          ]
        }
      end

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end

      context 'when a matching druid and symphony catalog link' do
        let(:obj) do
          create(:ar_dro, external_identifier: 'druid:bc640yg4341', identification:)
        end

        let(:identification) do
          {
            sourceId: 'sul:1234',
            catalogLinks: [
              { catalog: 'symphony', catalogRecordId: '10065784' }
            ]
          }
        end

        it 'returns true' do
          expect(migrator.migrate?).to be true
        end
      end
    end

    context 'when a non-matching druid' do
      let(:obj) do
        create(:ar_dro, external_identifier: 'druid:bc640yg4342')
      end

      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    let(:obj) do
      create(:ar_dro, external_identifier: 'druid:bc640yg4341', identification:)
    end

    let(:identification) do
      {
        sourceId: 'sul:1234',
        catalogLinks: [
          { catalog: 'symphony', catalogRecordId: '10065784', refresh: true }
        ]
      }
    end

    it 'adds changes link' do
      migrator.migrate
      expect(obj.identification['catalogLinks']).to eq [
        { 'catalog' => 'previous symphony', 'catalogRecordId' => '10065784', 'refresh' => false }
      ]
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
      expect(migrator.version_description).to eq 'Change Invalid Lane catkey to "previous symphony" identifier'
    end
  end
end
