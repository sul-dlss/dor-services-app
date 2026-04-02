# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::ExemplarWithCommitWithPublish do
  describe '.migration_strategy' do
    it 'returns commit_with_publish' do
      expect(described_class.migration_strategy).to eq :commit_with_publish
    end
  end
end
