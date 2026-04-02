# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::ExemplarWithCocinaUpdate do
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
end
