# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToDatacite::CreatorContributorFunder do
  let(:cocina_description) do
    cocina[:title] = [{ value: 'title' }]
    cocina[:purl] = 'https://purl.stanford.edu/cc123dd1234'
    Cocina::Models::Description.new(cocina)
  end
  let(:cocina_item) do
    Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.object,
                            label: 'This is my label',
                            version: 1,
                            administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                            description: cocina_description,
                            identification: { sourceId: 'cats:dogs' },
                            externalIdentifier: 'druid:cc123dd1234',
                            structural: {},
                            access: {})
  end
  let(:mapped_to_datacite) { described_class.new(cocina_item.description) }
  let(:mapped_datacite_creators) { mapped_to_datacite.attributes[:creators] }
  let(:mapped_datacite_contributors) {  mapped_to_datacite.attributes[:contributors] }
  let(:mapped_datacite_funding_references) { mapped_to_datacite.attributes[:fundingReferences] }

  context 'when part 1 of name or affiliation has ROR; part 2 may or may not be entered' do
    # NOTE: Per conversation with Amy 7/7/23, if part 1 of name or affiliation has ROR, drop part 2 if entered. Otherwise the
    # value would need to be mapped twice, once with the ROR and once with the more specific department, as the ROR
    # applies only to the institution.
    context 'when cited contributor with affiliation' do
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
                      value: 'Smith',
                      type: 'surname'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              note: [
                {
                  type: 'affiliation',
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
              ]
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          {
            nameType: 'Personal',
            name: 'Smith, Jane',
            givenName: 'Jane',
            familyName: 'Smith',
            affiliations: [
              {
                name: 'Stanford University',
                affiliationIdentifier: 'https://ror.org/00f54p054',
                affiliationIdentifierScheme: 'ROR',
                schemeURI: 'https://ror.org',
              }
            ]
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end
    end

    context 'when cited organizational creator with identifier', skip: 'organization affiliations not yet implemented in h2' do
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
          ]
        }
      end
      let(:expected_hash) do
        [
          {
            name: 'Stanford University',
            nameType: 'Organizational',
            nameIdentifiers: [
              {
                nameIdentifier: 'https://ror.org/00f54p054',
                nameIdentifierScheme: 'ROR',
                schemeURI: 'https://ror.org'
              }
            ]
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end
    end

    context 'when uncited contributor with affiliation and H2 role "Thesis advisor"' do
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
                      value: 'Smith',
                      type: 'surname'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'thesis advisor',
                  code: 'ths',
                  uri: 'http://id.loc.gov/vocabulary/relators/ths',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ],
              note: [
                {
                type: 'affiliation',
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
                  type: 'citation status',
                  value: 'false'
                }
              ]
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          {
            nameType: 'Personal',
            name: 'Smith, Jane',
            givenName: 'Jane',
            familyName: 'Smith',
            contributorType: 'Other',
            affiliations: [
              {
                name: 'Stanford University',
                affiliationIdentifier: 'https://ror.org/00f54p054',
                affiliationIdentifierScheme: 'ROR',
                schemeURI: 'https://ror.org'
              }
            ]
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end
    end

    context 'when uncited organizational contributor with identifier and H2 role "Degree granting institution"', skip: 'organization affiliations not yet implemented in h2' do
      let(:cocina) do
        {
          contributor: [
            {
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          contributor: {
            contributorType: 'Other',
            contributorName: {
              nameType: 'Organizational',
              value: 'Stanford University'
            },
            nameIdentifier: {
              nameIdentifierScheme: 'ROR',
              schemeURI: 'https://ror.org',
              value: 'https://ror.org/00f54p054'
            }
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end
    end

    context 'when uncited organizational contributor with identifier and H2 role "Funder"', skip: 'organization affiliations not yet implemented in h2' do
      let(:cocina) do
        {
          contributor: [
            {
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          fundingReference: {
            funderName: {
              value: 'Stanford University'
            },
            funderIdentifier: {
              funderIdentifierType: 'ROR',
              schemeURI: 'https://ror.org',
              value: 'https://ror.org/00f54p054'
            }
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end
    end
  end

  context 'when part 1 of name or affiliation does not have ROR and part 2 is entered' do
    # NOTE: If part 2 is NOT entered, part 1 maps the same as current single-value entry.
    #
    # In examples, user enters part 1 = "Stanford University", part 2 = "Woods Institute". The two parts of the value
    # are concatenated in order with comma and space.

    context 'when cited contributor with affiliation' do
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
                      value: 'Smith',
                      type: 'surname'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              note: [
                {
                  type: 'affiliation',
                  structuredValue: [
                    {
                      value: 'Stanford University'
                    },
                    {
                      value: 'Woods Institute'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          {
            nameType: 'Personal',
            name: 'Smith, Jane',
            givenName: 'Jane',
            familyName: 'Smith',
            affiliations: [
              {
                name: 'Stanford University, Woods Institute'
              }
            ]
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end
    end

    context 'when cited organizational contributor', skip: 'organization affiliations not yet implemented in h2' do
      let(:cocina) do
        {
          creator: [
            {
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          creator: {
            creatorName: {
              nameType: 'Organizational',
              value: 'Stanford University, Woods Institute'
            }
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end
    end

    context 'when uncited contributor with affiliation and H2 role "Thesis advisor"' do
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
                      value: 'Smith',
                      type: 'surname'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary',
              role: [
                {
                  value: 'thesis advisor',
                  code: 'ths',
                  uri: 'http://id.loc.gov/vocabulary/relators/ths',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ],
              note: [
                {
                  type: 'affiliation',
                  structuredValue: [
                    {
                      value: 'Stanford University'
                    },
                    {
                      value: 'Woods institute'
                    }
                  ]
                },
                {
                  type: 'citation status',
                  value: 'false'
                }
              ]
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          {
            nameType: 'Personal',
            name: 'Smith, Jane',
            givenName: 'Jane',
            familyName: 'Smith',
            contributorType: 'Other',
            affiliations: [
              {
                name: 'Stanford University, Woods Institute'
              }
            ]
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end
    end

    context 'when uncited organizational contributor with H2 role "Degree granting institution"', skip: 'organization affiliations not yet implemented in h2' do
      let(:cocina) do
        {
          contributor: [
            {
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          contributor: {
            contributorType: 'Other',
            contributorName: {
              nameType: 'Organizational',
              value: 'Stanford University, Woods Institute'
            }
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end

    end

    context 'when cited or uncited organizational contributor with H2 role "Funder"', skip: 'organization affiliations not yet implemented in h2' do
      let(:cocina) do
        {
          contributor: [
            {
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          fundingReference: {
            funderName: {
              value: 'Stanford University, Woods Institute'
            }
          }
        ]
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end
    end
  end
end
