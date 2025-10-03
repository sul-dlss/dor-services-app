# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge(purl: "https://purl.stanford.edu/#{bare_druid}")
    )
  end

  describe 'form mappings from Cocina to Solr mods_typeOfResource_ssimdv' do
    context 'when one MODS resource type' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      it 'includes value' do
        expect(doc).to include('mods_typeOfResource_ssim' => ['text']) # TODO: Remove
        expect(doc).to include('mods_typeOfResource_ssimdv' => ['text'])
      end
    end

    context 'when multiple MODS resource types' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            },
            {
              value: 'still image',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      it 'includes values' do
        expect(doc).to include('mods_typeOfResource_ssim' => ['text', 'still image']) # TODO: Remove
        expect(doc).to include('mods_typeOfResource_ssimdv' => ['text', 'still image'])
      end
    end

    context 'when MODS resource type is collection' do
      # derives from MODS attribute, not value
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'collection',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      it 'does not include value' do
        expect(doc).not_to include('mods_typeOfResource_ssim') # TODO: Remove
        expect(doc).not_to include('mods_typeOfResource_ssimdv')
      end
    end

    context 'when MODS resource type is manuscript' do
      # derives from MODS attribute, not value
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'manuscript',
              type: 'resource type',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      it 'does not includes value' do
        expect(doc).not_to include('mods_typeOfResource_ssim') # TODO: Remove
        expect(doc).not_to include('mods_typeOfResource_ssimdv')
      end
    end

    context 'when form is not a MODS resource type' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              type: 'resource type'
            }
          ]
        }
      end

      it 'does not includes value' do
        expect(doc).not_to include('mods_typeOfResource_ssim') # TODO: Remove
        expect(doc).not_to include('mods_typeOfResource_ssimdv')
      end
    end

    context 'when MODS resource type lacks type property' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          form: [
            {
              value: 'text',
              source: {
                value: 'MODS resource types'
              }
            }
          ]
        }
      end

      it 'includes value' do
        expect(doc).to include('mods_typeOfResource_ssim' => ['text']) # TODO: Remove
        expect(doc).to include('mods_typeOfResource_ssimdv' => ['text'])
      end
    end
  end
end
