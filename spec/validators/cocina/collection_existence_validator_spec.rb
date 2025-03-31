# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::CollectionExistenceValidator do
  let(:validator) { described_class.new(item) }

  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection) { build(:collection, id: collection_druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
  end

  context 'when a dor object does not belong to a collection' do
    let(:item) { build(:dro) }

    it 'returns true' do
      expect(validator.valid?).to be true
    end
  end

  context 'when a dor object belongs to a collection' do
    let(:item) do
      build(:dro).new(
        structural: {
          contains: [],
          isMemberOf: [collection_druid]
        }
      )
    end

    it 'returns true' do
      expect(validator.valid?).to be true
    end
  end

  context 'when a dor object belongs to a collection that is not found' do
    let(:item) do
      build(:dro).new(
        structural: {
          contains: [],
          isMemberOf: [collection_druid]
        }
      )
    end

    it 'returns false' do
      allow(CocinaObjectStore).to receive(:find)
        .with(collection_druid).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      expect(validator.valid?).to be false
    end
  end
end
