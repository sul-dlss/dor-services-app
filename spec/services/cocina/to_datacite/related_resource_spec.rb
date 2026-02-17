# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Cocina::ToDatacite::RelatedResource do
  subject(:attributes) do
    described_class.related_item_attributes(Cocina::Models::RelatedResource.new(related_resource))
  end

  context 'when related resource is blank hash' do
    let(:related_resource) { {} }

    it 'returns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when related resource has blank values' do
    let(:related_resource) { { title: [] } }

    it 'returns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when related resource has unmapped values' do
    let(:related_resource) { { contributor: [{ name: [{ value: 'A. Author' }] }] } }

    it 'returns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when related resource only has type' do
    let(:related_resource) { { type: 'has version' } }

    it 'returns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when related resource has a preferred citation' do
    let(:related_resource) do
      {
        note: [
          {
            value: 'Stanford University (Stanford, CA.). (2020). yadda yadda',
            type: 'preferred citation'
          }
        ]
      }
    end

    it 'returns related item attributes with title and identifier' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'References',
        titles: [{ title: 'Stanford University (Stanford, CA.). (2020). yadda yadda' }]
      )
    end
  end

  context 'when related resource has a title' do
    let(:related_resource) do
      {
        title: [
          {
            value: 'A paper'
          }
        ]
      }
    end

    it 'returns related item attributes with title' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'References',
        titles: [{ title: 'A paper' }]
      )
    end
  end

  context 'when related resource has an identifier URL' do
    let(:related_resource) do
      {
        access: {
          url: [
            {
              value: 'https://example.com/resource'
            }
          ]
        }
      }
    end

    it 'returns related item attributes with identifier' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'References',
        relatedItemIdentifier: 'https://example.com/resource',
        relatedItemIdentifierType: 'URL',
        titles: [{ title: 'https://example.com/resource' }]
      )
    end
  end

  context 'when related resource has a type' do
    let(:related_resource) do
      {
        type: 'derived from',
        title: [
          {
            value: 'A paper'
          }
        ]
      }
    end

    it 'returns related item attributes with mapped type' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'IsDerivedFrom',
        titles: [{ title: 'A paper' }]
      )
    end
  end

  context 'when related resource is a link to a DOI' do
    let(:related_resource) do
      {
        type: 'referenced by',
        dataCiteRelationType: 'IsReferencedBy',
        identifier: [
          {
            type: 'doi',
            uri: 'https://doi.org/10.1234/example.doi'
          }
        ]
      }
    end
    let(:related_identifier_attributes) do
      described_class.related_identifier_attributes(Cocina::Models::RelatedResource.new(related_resource))
    end

    it 'returns related item attributes with mapped type' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'IsReferencedBy',
        titles: [{ title: 'https://doi.org/10.1234/example.doi' }],
        relatedItemIdentifier: 'https://doi.org/10.1234/example.doi',
        relatedItemIdentifierType: 'DOI'
      )
      expect(related_identifier_attributes).to eq(
        resourceTypeGeneral: 'Other',
        relationType: 'IsReferencedBy',
        relatedIdentifier: 'https://doi.org/10.1234/example.doi',
        relatedIdentifierType: 'DOI'
      )
    end
  end

  context 'when related resource is a link to arXiv' do
    let(:related_resource) do
      {
        type: 'referenced by',
        dataCiteRelationType: 'IsReferencedBy',
        identifier: [
          {
            type: 'arxiv',
            uri: 'https://arxiv.org/abs/2402.17945'
          }
        ]
      }
    end
    let(:related_identifier_attributes) do
      described_class.related_identifier_attributes(Cocina::Models::RelatedResource.new(related_resource))
    end

    it 'returns related item attributes with mapped type' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'IsReferencedBy',
        titles: [{ title: 'https://arxiv.org/abs/2402.17945' }],
        relatedItemIdentifier: 'https://arxiv.org/abs/2402.17945',
        relatedItemIdentifierType: 'arXiv'
      )
      expect(related_identifier_attributes).to eq(
        resourceTypeGeneral: 'Other',
        relationType: 'IsReferencedBy',
        relatedIdentifier: 'https://arxiv.org/abs/2402.17945',
        relatedIdentifierType: 'arXiv'
      )
    end
  end

  context 'when related resource is a link to pubmed' do
    let(:related_resource) do
      {
        type: 'referenced by',
        dataCiteRelationType: 'IsReferencedBy',
        identifier: [
          {
            type: 'pmid',
            uri: 'https://pubmed.ncbi.nlm.nih.gov/31060017/'
          }
        ]
      }
    end
    let(:related_identifier_attributes) do
      described_class.related_identifier_attributes(Cocina::Models::RelatedResource.new(related_resource))
    end

    it 'returns related item attributes with mapped type' do
      expect(attributes).to eq(
        relatedItemType: 'Other',
        relationType: 'IsReferencedBy',
        titles: [{ title: 'https://pubmed.ncbi.nlm.nih.gov/31060017/' }],
        relatedItemIdentifier: 'https://pubmed.ncbi.nlm.nih.gov/31060017/',
        relatedItemIdentifierType: 'PMID'
      )
      expect(related_identifier_attributes).to eq(
        resourceTypeGeneral: 'Other',
        relationType: 'IsReferencedBy',
        relatedIdentifier: 'https://pubmed.ncbi.nlm.nih.gov/31060017/',
        relatedIdentifierType: 'PMID'
      )
    end
  end
end
