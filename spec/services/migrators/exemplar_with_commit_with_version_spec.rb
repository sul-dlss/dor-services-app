# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::ExemplarWithCommitWithVersion do
  describe '.migration_strategy' do
    it 'returns commit_with_version' do
      expect(described_class.migration_strategy).to eq :commit_with_version
    end
  end

  describe '.version_description' do
    it 'returns the version description' do
      expect(described_class.version_description).to eq 'Testing migration'
    end
  end
end
