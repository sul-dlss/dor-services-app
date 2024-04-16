# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveReleaseTags do
  subject(:migrator) { described_class.new(ar_cocina_object) }

  let(:ar_cocina_object) { create(:ar_dro) }

  describe '#migrate?' do
    subject { migrator.migrate? }

    context 'when a dro' do
      let(:ar_cocina_object) { create(:ar_dro, administrative: { hasAdminPolicy: 'druid:hy787xj5878', releaseTags: [] }) }

      it { is_expected.to be true }
    end

    context 'when a collection' do
      let(:ar_cocina_object) { create(:ar_collection, administrative: { hasAdminPolicy: 'druid:hy787xj5878', releaseTags: [] }) }

      it { is_expected.to be true }
    end

    context 'when an APO' do
      let(:ar_cocina_object) { create(:ar_admin_policy) }

      it { is_expected.to be false }
    end
  end

  describe 'migrate' do
    let(:ar_cocina_object) { create(:ar_dro, administrative: { hasAdminPolicy: 'druid:hy787xj5878', releaseTags: [] }) }

    it 'removes releaseTags' do
      migrator.migrate
      expect(ar_cocina_object.administrative).to eq({ 'hasAdminPolicy' => 'druid:hy787xj5878' })
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