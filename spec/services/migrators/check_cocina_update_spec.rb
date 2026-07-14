# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::CheckCocinaUpdate do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version: false, last_closed_version: false,
                        head_version: false)
  end

  let(:model_hash) do
    {
      'description' => { 'title' => [{ 'value' => 'Original title' }] }
    }
  end

  describe '.migration_strategy' do
    it 'returns cocina_update' do
      expect(described_class.migration_strategy).to eq :cocina_update
    end
  end

  describe '.version_description' do
    it 'returns the version description' do
      expect(described_class.version_description).to eq 'Testing migration'
    end
  end

  describe '.dryrun_only?' do
    it 'returns true' do
      expect(described_class.dryrun_only?).to be true
    end
  end

  describe '#migrate' do
    it 'returns the mutated model hash with an additional title' do
      result = migrator.migrate
      expect(result).to eq model_hash
      expect(result.dig('description', 'title')).to eq [{ 'value' => 'Original title' }, { 'value' => 'Test' }]
    end

    context 'when there are no titles' do
      let(:model_hash) do
        {
          'description' => { 'title' => [] }
        }
      end

      it 'adds a title' do
        expect(migrator.migrate.dig('description', 'title')).to eq [{ 'value' => 'Test' }]
      end
    end

    context 'when there is no description' do
      let(:model_hash) { { 'externalIdentifier' => 'druid:bc123df4567' } }

      it 'adds a description with a title' do
        expect(migrator.migrate['description']).to eq(
          'title' => [{ 'value' => 'Test' }]
        )
      end
    end
  end
end
