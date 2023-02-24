# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::Exemplar do
  subject(:migrator) { described_class.new(ar_cocina_object) }

  let(:ar_cocina_object) { create(:ar_dro) }

  describe '.druids' do
    it 'returns an array' do
      expect(described_class.druids).to be_an Array
    end
  end

  describe '#migrate?' do
    context 'when a matching druid' do
      let(:ar_cocina_object) { create(:ar_dro, external_identifier: 'druid:bc177tq6734') }

      it 'returns true' do
        expect(migrator.migrate?).to be true
      end
    end

    context 'when not a matching druid' do
      it 'returns false' do
        expect(migrator.migrate?).to be false
      end
    end
  end

  describe 'migrate' do
    let(:ar_cocina_object) { create(:ar_dro, label: 'Test DRO - migrated XYZ') }

    it 'updates label and title' do
      migrator.migrate
      expect(ar_cocina_object.label).to match(/Test DRO - migrated \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      expect(ar_cocina_object.description['title'].first['value']).to match(/Test DRO - migrated \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end
  end

  describe '#publish?' do
    it 'returns false as migrated SDR objects should not be published' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false as migrated SDR objects should not be versioned' do
      expect(migrator.version?).to be false
    end
  end

  describe '#version_description' do
    it 'raises an error as version? is never true' do
      expect { migrator.version_description }.to raise_error(NotImplementedError)
    end
  end
end
