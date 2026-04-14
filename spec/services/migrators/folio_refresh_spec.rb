# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::FolioRefresh do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version: false, last_closed_version: false,
                        head_version: false)
  end

  let(:model_hash) do
    {
      'identification' => {
        'barcode' => '36105121200849',
        'catalogLinks' => [
          {
            'catalog' => 'folio',
            'refresh' => true,
            'catalogRecordId' => 'a6061707'
          }
        ]
      }
    }
  end
  let(:marc_record) { instance_double(MARC::Record) }
  let(:description_props) { { 'title' => 'Test Title' } }

  before do
    allow(Catalog::MarcDump).to receive(:new).and_return(instance_double(Catalog::MarcDump, find: marc_record))
    allow(Cocina::FromMarc::Description).to receive(:props).and_return(description_props)
  end

  describe '#call' do
    it 'updates the description from MARC' do
      result = migrator.migrate
      expect(result['description']).to eq(description_props)
    end

    context 'when MarcDump raises NotFound' do
      before do
        marc_dump = instance_double(Catalog::MarcDump)
        allow(Catalog::MarcDump).to receive(:new).and_return(marc_dump)
        allow(marc_dump).to receive(:find).and_raise(Catalog::MarcDump::NotFound)
      end

      it 'raises Catalog::MarcDump::NotFound' do
        expect { migrator.migrate }.to raise_error(Catalog::MarcDump::NotFound)
      end
    end

    context 'when no refreshable_hrid' do
      let(:model_hash) { { 'identification' => { 'catalogLinks' => [] } } }

      it 'returns the model_hash unchanged' do
        expect(migrator.migrate).to eq(model_hash)
      end
    end
  end

  describe '.migration_strategy' do
    it 'returns :cocina_update' do
      expect(described_class.migration_strategy).to eq(:cocina_update)
    end
  end

  describe '.version_description' do
    it 'returns the version description' do
      expect(described_class.version_description).to eq('Refresh description from Folio.')
    end
  end
end
