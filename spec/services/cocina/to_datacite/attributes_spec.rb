# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToDatacite::Attributes do
  let(:attributes) { described_class.mapped_from_cocina(cocina_dro) }

  let(:druid) { 'druid:bb666bb1234' }
  let(:doi) { "10.25740/#{druid.split(':').last}" }
  let(:purl) { "http://purl.stanford.edu/#{druid.split(':').last}" }
  let(:label) { 'label' }
  let(:title) { 'title' }
  let(:apo_druid) { 'druid:pp000pp0000' }

  context 'with a minimal description' do
    let(:cocina_dro) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.object,
                              label: label,
                              version: 1,
                              description: {
                                title: [{ value: title }]
                              },
                              identification: {
                                sourceId: 'sul:8.559351',
                                doi: doi
                              },
                              access: {},
                              administrative: {
                                hasAdminPolicy: apo_druid
                              })
    end

    it 'creates the attributes hash' do
      expect(attributes).to eq(
        {
          doi: doi,
          prefix: '10.25740',
          creators: [],
          dates: [],
          publicationYear: 1964,
          publisher: 'to be implemented',
          subjects: [],
          titles: [{ title: title }]
        }
      )
    end
  end

  context 'with cocina description form, identifier, note, purl, relatedResource values' do
    let(:cocina_dro) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.object,
                              label: label,
                              version: 1,
                              description: {
                                form: [
                                  {
                                    structuredValue: [
                                      {
                                        value: 'Data',
                                        type: 'type'
                                      }
                                    ],
                                    source: {
                                      value: 'Stanford self-deposit resource types'
                                    },
                                    type: 'resource type'
                                  },
                                  {
                                    value: 'Dataset',
                                    type: 'resource type',
                                    uri: 'http://id.loc.gov/vocabulary/resourceTypes/dat',
                                    source: {
                                      uri: 'http://id.loc.gov/vocabulary/resourceTypes/'
                                    }
                                  },
                                  {
                                    value: 'Data sets',
                                    type: 'genre',
                                    uri: 'https://id.loc.gov/authorities/genreForms/gf2018026119',
                                    source: {
                                      code: 'lcgft'
                                    }
                                  },
                                  {
                                    value: 'dataset',
                                    type: 'genre',
                                    source: {
                                      code: 'local'
                                    }
                                  },
                                  {
                                    value: 'Dataset',
                                    type: 'resource type',
                                    source: {
                                      value: 'DataCite resource types'
                                    }
                                  }
                                ],
                                identifier: [
                                  {
                                    value: doi,
                                    type: 'DOI'
                                  }
                                ],
                                note: [
                                  {
                                    type: 'abstract',
                                    value: 'My paper is about dolphins.'
                                  }
                                ],
                                purl: purl,
                                relatedResource: [
                                  {
                                    note: [
                                      {
                                        value: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. yadda yadda.',
                                        type: 'preferred citation'
                                      }
                                    ]
                                  }
                                ],
                                title: [{ value: title }]
                              },
                              identification: {
                                sourceId: 'sul:8.559351',
                                doi: doi
                              },
                              access: {},
                              administrative: {
                                hasAdminPolicy: apo_druid
                              })
    end

    it 'populates types in the attributes hash' do
      expect(attributes).to eq(
        {
          doi: doi,
          prefix: '10.25740',
          alternateIdentifiers: [
            {
              alternateIdentifier: purl,
              alternateIdentifierType: 'PURL'
            }
          ],
          creators: [],
          dates: [],
          descriptions: [
            {
              description: 'My paper is about dolphins.',
              descriptionType: 'Abstract'
            }
          ],
          identifiers: [
            {
              identifier: doi,
              identifierType: 'DOI'
            }
          ],
          publicationYear: 1964,
          publisher: 'to be implemented',
          relatedItems: [
            {
              relatedItemType: 'Other',
              relationType: 'References',
              titles: [
                {
                  title: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. yadda yadda.'
                }
              ]
            }
          ],
          subjects: [],
          titles: [{ title: title }],
          types: {
            resourceTypeGeneral: 'Dataset',
            resourceType: 'Data'
          }
        }
      )
    end
  end

  context 'when cocina_dro is nil' do
    let(:cocina_dro) { nil }

    it 'attributes retuns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when cocina type is collection' do
    let(:cocina_dro) do
      Cocina::Models::Collection.new(externalIdentifier: druid,
                                     type: Cocina::Models::Vocab.collection,
                                     label: label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }]
                                     },
                                     identification: {},
                                     access: {},
                                     administrative: {
                                       hasAdminPolicy: apo_druid
                                     })
    end

    it 'attributes retuns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when cocina type is APO' do
    let(:cocina_dro) do
      Cocina::Models::AdminPolicy.new(externalIdentifier: druid,
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: label,
                                      version: 1,
                                      description: {
                                        title: [{ value: title }]
                                      },
                                      administrative: {
                                        hasAdminPolicy: apo_druid
                                      })
    end

    it 'attributes retuns nil' do
      expect(attributes).to be_nil
    end
  end
end
