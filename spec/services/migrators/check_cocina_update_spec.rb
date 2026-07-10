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
    it 'returns the mutated model hash with the title set to Test' do
      result = migrator.migrate
      expect(result).to eq model_hash
      expect(result.dig('description', 'title', 0, 'value')).to eq 'Test'
    end
  end
end
