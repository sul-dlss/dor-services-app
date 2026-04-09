# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::Exemplar do
  subject(:migrator) do
    described_class.new(model_hash: model_hash.deep_dup,
                        valid: true,
                        opened_version: false,
                        last_closed_version: false,
                        head_version: false)
  end

  describe 'migrate' do
    subject(:migrated_model_hash) { migrator.migrate }

    let(:model_hash) do
      {
        'externalIdentifier' => druid,
        'label' => 'Original label',
        'description' => {
          'title' => [
            { 'value' => 'Original title' }
          ]
        }
      }
    end

    context 'when the externalIdentifier is not one of the test druids' do
      let(:druid) { 'druid:bc029tv6106' }

      it 'does not change the model hash' do
        expect(migrated_model_hash).to eq(model_hash)
      end
    end

    context 'when the externalIdentifier matches a test druid' do
      let(:druid) { described_class::TEST_DRUIDS.first }

      it 'changes the label and title' do
        expect(migrated_model_hash['label']).to include('- migrated')
        expect(migrated_model_hash['description']['title'].first['value']).to include('- migrated')
      end
    end
  end

  describe '.migration_strategy' do
    it 'returns commit' do
      expect(described_class.migration_strategy).to eq :commit
    end
  end
end
