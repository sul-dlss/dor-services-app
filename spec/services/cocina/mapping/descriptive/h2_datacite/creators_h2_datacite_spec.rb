# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite creator mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  # H2 Authors to include in citation

  let(:cocina_description) do
    Cocina::Models::Description.new(cocina.merge(purl: Purl.for(druid: 'druid:bb423sd6663')), false, false)
  end
  let(:attributes) { Cocina::ToDatacite::CreatorContributorFunder.attributes(cocina_description) }

  describe 'Person and organization contributors' do
    let(:cocina) do
      {
        contributor: [
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
            status: 'primary',
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
            ]
          },
          {
            name: [
              {
                value: 'Stanford University'
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'Sponsor',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'sponsor',
                code: 'spn',
                uri: 'http://id.loc.gov/vocabulary/relators/spn',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      }
    end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators:
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          },
          {
            name: 'Stanford University',
            nameType: 'Organizational'
          }
        ],
        contributors: [],
        fundingReferences: []
      )
    end
  end

  describe 'Cited contributor with Event role' do
    let(:cocina) do
      {
        contributor: [
          {
            type: 'event',
            name: [
              {
                value: 'San Francisco Symphony Concert'
              }
            ],
            status: 'primary',
            role: [
              {
                value: 'Event',
                source: {
                  value: 'H2 contributor role terms'
                }
              }
            ]
          }
        ]
      }
    end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators: [
          {
            name: 'San Francisco Symphony Concert',
            nameType: 'Organizational'
          }
        ],
        contributors: [],
        fundingReferences: []
      )
    end
  end

  describe 'Cited contributor with Conference role' do
    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'LDCX'
              }
            ],
            type: 'conference',
            status: 'primary',
            role: [
              {
                value: 'Conference',
                source: {
                  value: 'H2 contributor role terms'
                }
              }
            ]
          }
        ]
      }
    end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators: [
          {
            name: 'LDCX',
            nameType: 'Organizational'
          }
        ],
        contributors: [],
        fundingReferences: []
      )
    end
  end

  describe 'Cited contributor with Funder role' do
    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Stanford University'
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
          }
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Organizational">Stanford University</creatorName>
    #       </creator>
    #     </creators>
    #     <fundingReferences>
    #       <fundingReference>
    #         <funderName>Stanford University</funderName>
    #       </fundingReference>
    #     <fundingReferences>
    #   XML
    # end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators: [],
        contributors: [],
        fundingReferences: [
          { funderName: 'Stanford University' }
        ]
      )
    end
  end

  describe 'Cited contributor with Publisher role' do
    let(:cocina) do
      {
        contributor: [
          {
            name: [
              {
                value: 'Stanford University Press'
              }
            ],
            type: 'organization',
            status: 'primary',
            role: [
              {
                value: 'Publisher',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'publisher',
                code: 'pbl',
                uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      }
    end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators: [],
        contributors: [
          {
            name: 'Stanford University Press',
            nameType: 'Organizational',
            contributorType: 'Distributor'
          }
        ],
        fundingReferences: []
      )
    end
  end

  describe 'Creator with ORCID' do
    let(:cocina) do
      {
        contributor: [
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
            status: 'primary',
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
            identifier: [
              {
                value: '0000-0000-0000-0000',
                type: 'ORCID',
                source: {
                  uri: 'https://orcid.org'
                }
              }
            ]
          }
        ]
      }
    end

    it 'populates attributes correctly' do
      expect(attributes).to eq(
        creators: [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford',
            nameIdentifiers: [
              {
                nameIdentifier: '0000-0000-0000-0000',
                nameIdentifierScheme: 'ORCID',
                schemeURI: 'https://orcid.org'
              }
            ]
          }
        ],
        contributors: [],
        fundingReferences: []
      )
    end
  end
end
