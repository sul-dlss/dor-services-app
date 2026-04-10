# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::Base do
  subject(:migrator) do
    migrator_class.new(model_hash: {}, valid: true, opened_version: false, last_closed_version: false,
                       head_version: false)
  end

  describe '#initialize' do
    context 'when the migration strategy is invalid' do
      let(:migrator_class) do
        Class.new(described_class) do
          def migrate
            model_hash
          end

          def self.migration_strategy
            :invalid
          end
        end
      end

      it 'raises an error' do
        expect { migrator }.to raise_error(ArgumentError, 'Invalid migration strategy')
      end
    end
  end
end
