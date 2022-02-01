# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailService do
  let(:instance) { described_class.new(object) }

  describe '#thumb' do
    subject { instance.thumb }

    context 'for a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'Collection of new maps of Africa',
                                       version: 1,
                                       cocinaVersion: '0.0.1',
                                       access: {})
      end

      it 'returns nil if there is no structural metadata' do
        expect(subject).to be_nil
      end
    end

    context 'for an item' do
      let(:druid) { 'druid:bc123df4567' }
      let(:apo_druid) { 'druid:pp000pp0000' }

      context 'with no structural metadata' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: build_cocina_description_metadata_1(druid),
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid })
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when no specific thumbs are specified' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: build_cocina_description_metadata_1(druid),
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: build_cocina_structural_metadata_1)
        end

        it 'finds the first image as the thumb' do
          expect(subject).to eq('bc123df4567/wt183gy6220_00_0001.jp2')
        end
      end

      context 'when an externalFile image resource is the only image' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: build_cocina_description_metadata_1(druid),
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: build_cocina_structural_metadata_2)
        end

        it 'returns the image as the thumb' do
          expect(subject).to eq('cg767mn6478_1/2542A.jp2')
        end
      end

      context 'when no thumb is identified' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: druid,
                                  type: Cocina::Models::Vocab.object,
                                  label: 'A new map of Africa',
                                  version: 1,
                                  description: build_cocina_description_metadata_1(druid),
                                  identification: {},
                                  access: {},
                                  administrative: { hasAdminPolicy: apo_druid },
                                  structural: build_cocina_structural_metadata_3)
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
