# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ApoExistenceValidator do
  let(:validator) { described_class.new(item) }

  let(:apo_druid) { 'druid:jt959wc5586' }
  let(:apo) { build(:admin_policy, id: apo_druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(apo)
  end

  context 'with a dor object with a valid APO' do
    let(:item) { build(:dro, admin_policy_id: apo_druid) }

    it 'returns true' do
      expect(validator.valid?).to be true
    end
  end

  context 'when a dor object as an APO that is not found' do
    let(:item) { build(:dro, admin_policy_id: 'druid:df123cd4567') }

    it 'returns false' do
      allow(CocinaObjectStore).to receive(:find).with('druid:df123cd4567').and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      expect(validator.valid?).to be false
    end
  end

  context 'when a dor object as an APO druid that is not an APO' do
    let(:collection_druid) { 'druid:cc111cc1111' }
    let(:collection) { build(:collection, id: collection_druid) }
    let(:item) { build(:dro, admin_policy_id: collection_druid) }

    before do
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
    end

    it 'returns false' do
      expect(validator.valid?).to be false
    end
  end
end
