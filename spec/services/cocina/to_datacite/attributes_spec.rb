# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToDatacite::Attributes do
  let(:attributes) { described_class.mapped_from_cocina(cocina_item, url:) }
  let(:cocina_item) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::ObjectType.object,
                            label:,
                            version: 1,
                            description: {
                              title: [{ value: title }],
                              purl:
                            },
                            identification: {
                              sourceId: 'sul:8.559351',
                              doi:
                            },
                            access: {},
                            administrative: {
                              hasAdminPolicy: apo_druid
                            },
                            structural: {})
  end

  let(:druid) { 'druid:bb666bb1234' }
  let(:doi) { "10.25740/#{druid.split(':').last}" }
  let(:purl) { "https://purl.stanford.edu/#{druid.split(':').last}" }
  let(:label) { 'label' }
  let(:title) { 'title' }
  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:url) { nil }

  before do
    allow(Time.zone).to receive(:today).and_return(instance_double(Date, year: 2011))
  end

  context 'with a minimal description' do
    it 'creates the attributes hash' do
      expect(attributes).to eq(
        {
          event: 'publish',
          url: 'https://purl.stanford.edu/bb666bb1234',
          creators: [],
          contributors: [],
          fundingReferences: [],
          dates: [],
          publicationYear: '2011',
          publisher: 'Stanford Digital Repository',
          titles: [{ title: }],
          alternateIdentifiers: [
            {
              alternateIdentifier: purl,
              alternateIdentifierType: 'PURL'
            }
          ],
          relatedItems: [],
          relatedIdentifiers: []
        }
      )
    end
  end

  context 'with a provided url' do
    let(:url) { 'https://example.com' }

    it 'uses the url in the attributes hash' do
      expect(attributes[:url]).to eq(url)
    end
  end

  context 'with an embargo' do
    let(:cocina_item) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label:,
                              version: 1,
                              description: {
                                title: [{ value: title }],
                                purl:
                              },
                              identification: {
                                sourceId: 'sul:8.559351',
                                doi:
                              },
                              access: {
                                embargo: {
                                  releaseDate: '2031-07-01T00:00:00.000+00:00'
                                }
                              },
                              administrative: {
                                hasAdminPolicy: apo_druid
                              },
                              structural: {})
    end

    it 'creates the attributes hash' do
      expect(attributes).to eq(
        {
          event: 'publish',
          url: 'https://purl.stanford.edu/bb666bb1234',
          creators: [],
          contributors: [],
          fundingReferences: [],
          dates: [],
          publicationYear: '2031',
          publisher: 'Stanford Digital Repository',
          titles: [{ title: }],
          alternateIdentifiers: [
            {
              alternateIdentifier: purl,
              alternateIdentifierType: 'PURL'
            }
          ],
          relatedItems: [],
          relatedIdentifiers: []
        }
      )
    end
  end

  context 'with a fully described object' do
    let(:cocina_item) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.object,
                              label:,
                              version: 1,
                              description: {
                                contributor: [
                                  {
                                    name: [
                                      {
                                        value: 'National Institute of Health'
                                      }
                                    ],
                                    type: 'organization',
                                    status: 'primary',
                                    role: [
                                      {
                                        value: 'Funder',
                                        source: {
                                          value: 'H2 contributor role terms'
                                        }
                                      },
                                      {
                                        value: 'funder',
                                        code: 'fnd',
                                        uri: 'http://id.loc.gov/vocabulary/relators/fnd',
                                        source: {
                                          code: 'marcrelator',
                                          uri: 'http://id.loc.gov/vocabulary/relators/'
                                        }
                                      }
                                    ]
                                  },
                                  {
                                    name: [
                                      {
                                        structuredValue: [
                                          {
                                            value: 'Jane',
                                            type: 'forename'
                                          },
                                          {
                                            value: 'Stanford',
                                            type: 'surname'
                                          }
                                        ]
                                      }
                                    ],
                                    type: 'person',
                                    role: [
                                      {
                                        value: 'Author',
                                        source: {
                                          value: 'H2 contributor role terms'
                                        }
                                      },
                                      {
                                        value: 'author',
                                        code: 'aut',
                                        uri: 'http://id.loc.gov/vocabulary/relators/aut',
                                        source: {
                                          code: 'marcrelator',
                                          uri: 'http://id.loc.gov/vocabulary/relators/'
                                        }
                                      }
                                    ],
                                    affiliation: [
                                      {
                                        structuredValue: [
                                          {
                                            value: 'Stanford University',
                                            identifier: [
                                              {
                                                uri: 'https://ror.org/00f54p054',
                                                type: 'ROR',
                                                source: {
                                                  code: 'ror'
                                                }
                                              }
                                            ]
                                          },
                                          {
                                            value: 'Woods Institute for the Environment'
                                          }
                                        ]
                                      }
                                    ],
                                    note: [
                                      {
                                        type: 'citation status',
                                        value: 'false'
                                      }
                                    ]
                                  },
                                  {
                                    name: [
                                      {
                                        structuredValue: [
                                          {
                                            value: 'John',
                                            type: 'forename'
                                          },
                                          {
                                            value: 'Stanford',
                                            type: 'surname'
                                          }
                                        ]
                                      }
                                    ],
                                    type: 'person',
                                    role: [
                                      {
                                        value: 'Author',
                                        source: {
                                          value: 'H2 contributor role terms'
                                        }
                                      },
                                      {
                                        value: 'author',
                                        code: 'aut',
                                        uri: 'http://id.loc.gov/vocabulary/relators/aut',
                                        source: {
                                          code: 'marcrelator',
                                          uri: 'http://id.loc.gov/vocabulary/relators/'
                                        }
                                      }
                                    ],
                                    affiliation: [
                                      {
                                        value: 'Stanford University',
                                        identifier: [
                                          {
                                            uri: 'https://ror.org/00f54p054',
                                            type: 'ROR',
                                            source: {
                                              code: 'ror'
                                            }
                                          }
                                        ]
                                      }
                                    ],
                                    note: [
                                      {
                                        type: 'citation status',
                                        value: 'false'
                                      }
                                    ]
                                  },
                                  {
                                    name: [
                                      {
                                        structuredValue: [
                                          {
                                            value: 'Stanford University',
                                            identifier: [
                                              {
                                                type: 'ROR',
                                                uri: 'https://ror.org/00f54p054',
                                                source: {
                                                  code: 'ror'
                                                }
                                              }
                                            ]
                                          },
                                          {
                                            value: 'Department of Animal Husbandry'
                                          }
                                        ]
                                      }
                                    ],
                                    type: 'organization',
                                    status: 'primary',
                                    role: [
                                      {
                                        value: 'degree granting institution',
                                        code: 'dgg',
                                        uri: 'http://id.loc.gov/vocabulary/relators/dgg',
                                        source: {
                                          code: 'marcrelator',
                                          uri: 'http://id.loc.gov/vocabulary/relators/'
                                        }
                                      }
                                    ],
                                    note: [
                                      {
                                        type: 'citation status',
                                        value: 'false'
                                      }
                                    ]
                                  }
                                ],
                                form: [
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
                                purl:,
                                relatedResource: [
                                  {
                                    note: [
                                      {
                                        value: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. yadda yadda.', # rubocop:disable Layout/LineLength
                                        type: 'preferred citation'
                                      }
                                    ]
                                  },
                                  {
                                    type: 'referenced by',
                                    dataCiteRelationType: 'IsReferencedBy',
                                    identifier: [
                                      {
                                        type: 'doi',
                                        uri: 'https://doi.org/10.1234/example.doi'
                                      }
                                    ]
                                  },
                                  {} # Blank will be removed.
                                ],
                                subject: [
                                  {
                                    value: 'Marine biology',
                                    type: 'topic',
                                    uri: 'http://id.worldcat.org/fast/1009447',
                                    source: {
                                      code: 'fast',
                                      uri: 'http://id.worldcat.org/fast/'
                                    }
                                  }
                                ],
                                title: [{ value: title }]
                              },
                              identification: {
                                sourceId: 'sul:8.559351',
                                doi:
                              },
                              access: {
                                license: 'https://creativecommons.org/publicdomain/mark/1.0/'
                              },
                              administrative: {
                                hasAdminPolicy: apo_druid
                              },
                              structural: {})
    end

    it 'populates the attributes hash correctly' do
      expect(attributes).to eq(
        {
          event: 'publish',
          url: 'https://purl.stanford.edu/bb666bb1234',
          alternateIdentifiers: [
            {
              alternateIdentifier: purl,
              alternateIdentifierType: 'PURL'
            }
          ],
          creators: [
            {
              name: 'Stanford, Jane',
              givenName: 'Jane',
              familyName: 'Stanford',
              nameType: 'Personal',
              affiliation: [
                {
                  affiliationIdentifier: 'https://ror.org/00f54p054',
                  affiliationIdentifierScheme: 'ROR',
                  name: 'Stanford University',
                  schemeUri: 'https://ror.org/'
                }
              ]
            },
            {
              name: 'Stanford, John',
              givenName: 'John',
              familyName: 'Stanford',
              nameType: 'Personal',
              affiliation: [
                {
                  affiliationIdentifier: 'https://ror.org/00f54p054',
                  affiliationIdentifierScheme: 'ROR',
                  name: 'Stanford University',
                  schemeUri: 'https://ror.org/'
                }
              ]
            },
            {
              name: 'Stanford University',
              nameType: 'Organizational',
              nameIdentifiers: [
                {
                  nameIdentifier: 'https://ror.org/00f54p054',
                  nameIdentifierScheme: 'ROR'
                }
              ]
            }
          ],
          contributors: [],
          fundingReferences: [
            {
              funderName: 'National Institute of Health'
            }
          ],
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
          publicationYear: '2011',
          publisher: 'Stanford Digital Repository',
          relatedItems: [
            {
              relatedItemType: 'Other',
              relationType: 'References',
              titles: [
                {
                  title: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. yadda yadda.'
                }
              ]
            },
            {
              relatedItemType: 'Other',
              relationType: 'IsReferencedBy',
              titles: [
                {
                  title: 'https://doi.org/10.1234/example.doi'
                }
              ],
              relatedItemIdentifier: 'https://doi.org/10.1234/example.doi',
              relatedItemIdentifierType: 'DOI'
            }
          ],
          relatedIdentifiers: [
            {
              resourceTypeGeneral: 'Other',
              relationType: 'IsReferencedBy',
              relatedIdentifier: 'https://doi.org/10.1234/example.doi',
              relatedIdentifierType: 'DOI'
            }
          ],
          rightsList: [
            {
              rights: 'https://creativecommons.org/publicdomain/mark/1.0/'
            }
          ],
          subjects: [
            {
              subject: 'Marine biology',
              subjectScheme: 'fast',
              valueURI: 'http://id.worldcat.org/fast/1009447',
              schemeURI: 'http://id.worldcat.org/fast/'
            }
          ],
          titles: [{ title: }],
          types: {
            resourceTypeGeneral: 'Dataset',
            resourceType: ''
          }
        }
      )
    end
  end

  context 'when cocina_item is nil' do
    let(:cocina_item) { nil }

    it 'attributes retuns nil' do
      expect(attributes).to be_nil
    end
  end

  context 'when cocina type is collection' do
    let(:cocina_item) do
      Cocina::Models::Collection.new(externalIdentifier: druid,
                                     type: Cocina::Models::ObjectType.collection,
                                     label:,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }],
                                       purl:
                                     },
                                     identification: { sourceId: 'sul:123' },
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
    let(:cocina_item) do
      Cocina::Models::AdminPolicy.new(externalIdentifier: druid,
                                      type: Cocina::Models::ObjectType.admin_policy,
                                      label:,
                                      version: 1,
                                      description: {
                                        title: [{ value: title }],
                                        purl:
                                      },
                                      administrative: {
                                        hasAdminPolicy: apo_druid,
                                        hasAgreement: 'druid:bb423sd6663',
                                        accessTemplate: { view: 'world', download: 'world' }
                                      })
    end

    it 'attributes retuns nil' do
      expect(attributes).to be_nil
    end
  end
end
