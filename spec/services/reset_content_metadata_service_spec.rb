# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetContentMetadataService do
  let(:item_druid) { 'druid:bc123df4567' }
  let(:cocina_item) do
    build(:dro, id: item_druid).new(
      structural: structural
    )
  end
  let(:service) { described_class.new(cocina_item: cocina_item) }

  before do
    allow(Honeybadger).to receive(:notify)
  end

  describe '#reset' do
    context 'with no constituent druids' do
      subject(:updated_cocina_item) { service.reset }

      context 'when item has no structural metadata' do
        let(:structural) { {} }

        it 'returns item with structural metadata containing no orders' do
          expect(updated_cocina_item).to match_cocina_object_with(structural: { hasMemberOrders: [] })
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has structural metadata with no orders' do
        let(:structural) do
          Cocina::Models::DROStructural.new(
            isMemberOf: ['druid:fd234jh8769'],
            contains: [
              {
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
                version: 1,
                type: Cocina::Models::FileSetType.file,
                label: 'Page 1',
                structural: {
                  contains: [
                    {
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                      version: 1,
                      type: Cocina::Models::ObjectType.file,
                      filename: '00001.jp2',
                      label: '00001.jp2',
                      hasMimeType: 'image/jp2',
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      },
                      access: {
                        view: 'dark',
                        download: 'none'
                      },
                      hasMessageDigests: []
                    }
                  ]
                }
              }
            ]
          ).to_h
        end

        it 'returns item with structural metadata containing no orders' do
          expect(updated_cocina_item).to match_cocina_object_with(structural: structural)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one or more non-member orders' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: [],
                viewingDirection: 'left-to-right'
              }
            ]
          }
        end

        it 'returns only non-member orders' do
          expect(updated_cocina_item).to match_cocina_object_with(structural: structural)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one member order' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: ['druid:bj876jy8756']
              }
            ]
          }
        end

        it 'returns empty member order' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: []
            }
          )
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one or more member orders' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: ['druid:bj876jy8756']
              },
              {
                members: ['druid:bj776jy8755']
              }
            ]
          }
        end

        it 'returns empty member order and notifies of data error' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: []
            }
          )
          expect(Honeybadger).to have_received(:notify)
            .once
            .with(
              "[DATA ERROR] item #{item_druid} has multiple member orders",
              {
                tags: 'data_error',
                context: { druid: item_druid }
              }
            )
        end
      end
    end

    context 'with constituent druids' do
      subject(:updated_cocina_item) { service.reset(constituent_druids: constituent_druids) }

      let(:constituent_druids) { ['druid:bj876jy8756', 'druid:bj776jy8755'] }

      context 'when item has no structural metadata' do
        let(:structural) { {} }

        it 'returns single member order' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: [
                {
                  members: constituent_druids
                }
              ]
            }
          )
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has structural metadata with no orders' do
        let(:structural) do
          {
            isMemberOf: ['druid:fd234jh8769'],
            contains: [
              {
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
                version: 1,
                type: Cocina::Models::FileSetType.file,
                label: 'Page 1',
                structural: {
                  contains: [
                    {
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                      version: 1,
                      type: Cocina::Models::ObjectType.file,
                      filename: '00001.jp2',
                      label: '00001.jp2',
                      hasMimeType: 'image/jp2',
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      },
                      access: {
                        view: 'dark',
                        download: 'none'
                      },
                      hasMessageDigests: []
                    }
                  ]
                }
              }
            ]
          }
        end

        it 'returns single member order' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              isMemberOf: ['druid:fd234jh8769'],
              hasMemberOrders: [
                {
                  members: constituent_druids
                }
              ],
              contains: [
                {
                  externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
                  version: 1,
                  type: Cocina::Models::FileSetType.file,
                  label: 'Page 1',
                  structural: {
                    contains: [
                      {
                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                        version: 1,
                        type: Cocina::Models::ObjectType.file,
                        filename: '00001.jp2',
                        label: '00001.jp2',
                        hasMimeType: 'image/jp2',
                        administrative: {
                          publish: false,
                          sdrPreserve: true,
                          shelve: false
                        },
                        access: {
                          view: 'dark',
                          download: 'none',
                          controlledDigitalLending: false
                        },
                        hasMessageDigests: []
                      }
                    ]
                  }
                }
              ]
            }
          )
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one or more non-member orders' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: [],
                viewingDirection: 'left-to-right'
              }
            ]
          }
        end

        it 'returns single member order plus non-member orders' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: [
                {
                  members: [],
                  viewingDirection: 'left-to-right'
                },
                {
                  members: constituent_druids
                }
              ]
            }
          )
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one member order' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: ['druid:bj876jy8756']
              }
            ]
          }
        end

        it 'returns new member order' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: [
                {
                  members: constituent_druids
                }
              ]
            }
          )
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when item has one or more member orders' do
        let(:structural) do
          {
            hasMemberOrders: [
              {
                members: ['druid:bj876jy8756']
              },
              {
                members: ['druid:bj776jy8755']
              }
            ]
          }
        end

        it 'returns new member order and notifies of data error' do
          expect(updated_cocina_item).to match_cocina_object_with(
            structural: {
              hasMemberOrders: [
                {
                  members: constituent_druids
                }
              ]
            }
          )
          expect(Honeybadger).to have_received(:notify)
            .once
            .with(
              "[DATA ERROR] item #{item_druid} has multiple member orders",
              {
                tags: 'data_error',
                context: { druid: item_druid }
              }
            )
        end
      end
    end
  end
end
