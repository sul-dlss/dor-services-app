# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::CollectionExistenceValidator do
  let(:validator) { described_class.new(item) }

  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection) { Dor::Collection.new(pid: collection_druid) }

  before do
    allow(Dor).to receive(:find).with(collection_druid).and_return(collection)
  end

  context 'when a dor object does not belong to a collection' do
    let(:item) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
        version: 1,
        administrative: {
          hasAdminPolicy: 'druid:df123cd4567'
        },
        access: {}
      )
    end

    it 'returns true' do
      expect(validator.valid?).to be true
    end
  end

  context 'when a dor object belongs to a collection' do
    let(:item) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
        version: 1,
        administrative: {
          hasAdminPolicy: 'druid:df123cd4567'
        },
        access: {},
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
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
        version: 1,
        administrative: {
          hasAdminPolicy: 'druid:df123cd4567'
        },
        access: {},
        structural: {
          contains: [],
          isMemberOf: [collection_druid]
        }
      )
    end

    it 'returns false' do
      allow(Dor).to receive(:find).with(collection_druid).and_return(nil)
      expect(validator.valid?).to be false
    end
  end
end
