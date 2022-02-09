# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ApoExistenceValidator do
  let(:validator) { described_class.new(item) }

  let(:apo_druid) { 'druid:jt959wc5586' }
  let(:apo) do
    Cocina::Models::AdminPolicy.new({ cocinaVersion: '0.0.1',
                                      externalIdentifier: apo_druid,
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: { hasAdminPolicy: 'druid:hy787xj5878', hasAgreement: 'druid:bb033gt0615' },
                                      description: {
                                        title: [{ value: 'Test Admin Policy' }],
                                        purl: 'https://purl.stanford.edu/jt959wc5586'
                                      } })
  end

  before do
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(apo)
  end

  context 'with a dor object with a valid APO' do
    let(:item) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
        version: 1,
        administrative: {
          hasAdminPolicy: apo_druid
        },
        access: {}
      )
    end

    it 'returns true' do
      expect(validator.valid?).to be true
    end
  end

  context 'when a dor object as an APO that is not found' do
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

    it 'returns false' do
      allow(CocinaObjectStore).to receive(:find).with('druid:df123cd4567').and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      expect(validator.valid?).to be false
    end
  end

  context 'when a dor object as an APO druid that is not an APO' do
    let(:collection_druid) { 'druid:cc111cc1111' }
    let(:collection) do
      Cocina::Models::Collection.new(externalIdentifier: collection_druid,
                                     type: Cocina::Models::Vocab.collection,
                                     label: 'Collection of new maps of Africa',
                                     version: 1,
                                     cocinaVersion: '0.0.1',
                                     access: {})
    end
    let(:item) do
      Cocina::Models::DRO.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
        version: 1,
        administrative: {
          hasAdminPolicy: collection_druid
        },
        access: {}
      )
    end

    before do
      allow(CocinaObjectStore).to receive(:find).with(collection_druid).and_return(collection)
    end

    it 'returns false' do
      expect(validator.valid?).to be false
    end
  end
end
