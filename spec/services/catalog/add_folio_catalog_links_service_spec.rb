# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::AddFolioCatalogLinksService do
  subject(:synced_object) { described_class.new(cocina_object).add }

  context 'when the object does not have catalog links (AdminPolicy)' do
    let(:cocina_object) { build(:admin_policy) }

    it 'does not change the object' do
      expect(synced_object).to eq cocina_object
    end
  end

  context 'when the catalog links are empty' do
    let(:cocina_object) { build(:dro) }

    it 'does not change the object' do
      expect(synced_object).to eq cocina_object
    end
  end

  context 'when there are catalog links' do
    let(:cocina_object) do
      build(:dro).new(identification: {
                        sourceId: 'sul:1234',
                        catalogLinks: [
                          { catalog: 'symphony', catalogRecordId: '12345', refresh: true },
                          { catalog: 'symphony', catalogRecordId: '23456', refresh: false },
                          # Not migrating.
                          { catalog: 'symphony', catalogRecordId: '10872078', refresh: false },
                          { catalog: 'previous symphony', catalogRecordId: '34567', refresh: false },
                          { catalog: 'folio', catalogRecordId: 'a45678', refresh: false },
                          { catalog: 'previous folio', catalogRecordId: 'a56789', refresh: false },
                          # Lane record should not be dropped.
                          { catalog: 'folio', catalogRecordId: 'L6789', refresh: false }
                        ]
                      })
    end

    it 'syncs the catalogLinks' do
      expect(synced_object.identification.catalogLinks.map(&:to_h)).to eq [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true },
        { catalog: 'folio', catalogRecordId: 'a23456', refresh: false },
        { catalog: 'symphony', catalogRecordId: '23456', refresh: false },
        { catalog: 'symphony', catalogRecordId: '10872078', refresh: false },
        { catalog: 'previous symphony', catalogRecordId: '34567', refresh: false },
        { catalog: 'previous folio', catalogRecordId: 'a56789', refresh: false },
        { catalog: 'folio', catalogRecordId: 'L6789', refresh: false }
      ]
    end
  end

  context 'when there is no existing folio link' do
    let(:cocina_object) do
      build(:dro).new(identification: {
                        sourceId: 'sul:1234',
                        catalogLinks: [
                          { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
                        ]
                      })
    end

    it 'adds the catalogLinks' do
      expect(synced_object.identification.catalogLinks.map(&:to_h)).to eq [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
    end
  end

  context 'when add is called multiple times' do
    let(:cocina_object) do
      build(:dro).new(identification: {
                        sourceId: 'sul:1234',
                        catalogLinks: [
                          { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
                        ]
                      })
    end
    let(:resynced_object) { described_class.new(synced_object).add }

    it 'syncs the catalogLinks' do
      expect(synced_object.identification.catalogLinks.map(&:to_h)).to eq [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
      expect(resynced_object.identification.catalogLinks.map(&:to_h)).to eq [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
    end
  end

  context 'when a collection' do
    let(:cocina_object) do
      build(:collection).new(identification: {
                               sourceId: 'sul:1234',
                               catalogLinks: [
                                 { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
                               ]
                             })
    end

    it 'syncs the catalogLinks' do
      expect(synced_object.identification.catalogLinks.map(&:to_h)).to eq [
        { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
        { catalog: 'symphony', catalogRecordId: '12345', refresh: true }
      ]
    end
  end
end
