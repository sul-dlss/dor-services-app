# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite contributor mappings (H2 specific)' do
  # Full role mapping: https://docs.google.com/spreadsheets/d/1CvEd_NODprNhM2D9VfvJBFs1jfAMEUr0kDxXHe2HkL4/edit?usp=sharing
  # H2 Authors to include in citation map to DataCite creators
  ## Identified in cocina by absence of contributor.note with type 'citation status' and value 'false'
  ## Map contributor.name to DataCite creators.name, no role
  # H2 Additional contributors map to DataCite contributors
  ## Identified in cocina by:
  ### Having contributor.note with type 'citation status' and value 'false'
  ## Map name to DataCite contributors.name
  ## Map role with source 'marcrelator' to DataCite contributorType following the mapping linked above
  ## TODO: Implement updated H2-cocina mappings that include DataCite role and citation status note
  # EXCEPTION: if marcrelator role is 'funder'
  ## Do not map to DataCite contributors.name
  ## Instead map to DataCite fundingReference.funderName

  let(:cocina_description) { Cocina::Models::Description.new(cocina.merge(purl: Purl.for(druid: 'druid:bb423sd6663')), false, false) }
  let(:attributes) { Cocina::ToDatacite::CreatorContributorFunder.attributes(cocina_description) }
  let(:creator_attributes) { attributes[:creators] }
  let(:contributor_attributes) { attributes[:contributors] }
  let(:funder_attributes) { attributes[:fundingReferences] }

  describe 'Cited contributor with author role' do
    # Authors to include in citation
    ## Jane Stanford. Author.

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
          }
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end
  end

  describe 'Multiple cited contributors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## Leland Stanford. Author.

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
                structuredValue: [
                  {
                    value: 'Leland',
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
            ]
          }
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Leland</creatorName>
    #         <givenName>Leland</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          },
          {
            name: 'Stanford, Leland',
            nameType: 'Personal',
            givenName: 'Leland',
            familyName: 'Stanford'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with cited organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    ## Stanford University. Sponsor.

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
                value: 'Data collector',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'compiler',
                code: 'com',
                uri: 'http://id.loc.gov/vocabulary/relators/com',
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

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #       <creator>
    #         <creatorName nameType="Organizational">Stanford University</creatorName>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
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
        ]
      )
    end
  end

  describe 'Cited organization' do
    # Authors to include in citation
    ## Stanford University. Host institution.

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
                value: 'Host institution',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'host institution',
                code: 'his',
                uri: 'http://id.loc.gov/vocabulary/relators/his',
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
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford University',
            nameType: 'Organizational'
          }
        ]
      )
    end
  end

  describe 'Multiple cited organizations' do
    # Authors to include in citation
    ## Stanford University. Host institution.
    ## Department of English. Department.

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
                value: 'Host institution',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'host institution',
                code: 'his',
                uri: 'http://id.loc.gov/vocabulary/relators/his',
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
                value: 'Department of English'
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'Department',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'host institution',
                code: 'his',
                uri: 'http://id.loc.gov/vocabulary/relators/his',
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
    #       <creator>
    #         <creatorName nameType="Organizational">Department of English</creatorName>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford University',
            nameType: 'Organizational'
          },
          {
            name: 'Department of English',
            nameType: 'Organizational'
          }
        ]
      )
    end
  end

  describe 'Cited and uncited authors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Leland Stanford. Contributing author.
    # Add contributor role to names in Additional contributors section.

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
                structuredValue: [
                  {
                    value: 'Leland',
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
                value: 'Contributing author',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'contributor',
                code: 'ctb',
                uri: 'http://id.loc.gov/vocabulary/relators/ctb',
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
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <contributors>
    #       <contributor contributorType="Other">
    #         <contributorName nameType="Personal">Stanford, Leland</contributorName>
    #         <givenName>Leland</givenName>
    #         <familyName>Stanford</familyName>
    #       </contributor>
    #     </contributors>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'Stanford, Leland',
            nameType: 'Personal',
            givenName: 'Leland',
            familyName: 'Stanford',
            contributorType: 'Other'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with uncited sponsoring organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Sponsor.

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
                value: 'Data collector',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'compiler',
                code: 'com',
                uri: 'http://id.loc.gov/vocabulary/relators/com',
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
            ],
            note: [
              {
                type: 'citation status',
                value: 'false'
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
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <contributors>
    #       <contributor contributorType="Sponsor">
    #         <contributorName nameType="Organizational">Stanford University</contributorName>
    #       </contributor>
    #     </contributors>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'Stanford University',
            nameType: 'Organizational',
            contributorType: 'Sponsor'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with Event role' do
    # Authors to include in citation
    ## San Francisco Symphony Concert. Event.

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

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Organizational">San Francisco Symphony Concert</creatorName>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'San Francisco Symphony Concert',
            nameType: 'Organizational'
          }
        ]
      )
    end
  end

  describe 'Cited contributor and uncited contributor with Event role' do
    # Authors to include in citation
    ## Jane Stanford. Event organizer.
    # Additional contributors
    ## San Francisco Symphony Concert. Event.

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
                value: 'Event organizer',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'organizer',
                code: 'orm',
                uri: 'http://id.loc.gov/vocabulary/relators/orm',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          },
          {
            type: 'event',
            name: [
              {
                value: 'San Francisco Symphony Concert'
              }
            ],
            role: [
              {
                value: 'Event',
                source: {
                  value: 'H2 contributor role terms'
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
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <contributors>
    #       <contributor contributorType="Other">
    #         <contributorName nameType="Organizational">San Francisco Symphony Concert</contributorName>
    #       </contributor>
    #     </contributors>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'San Francisco Symphony Concert',
            nameType: 'Organizational',
            contributorType: 'Other'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with Conference role' do
    # Authors to include in citation
    ## LDCX. Conference.

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

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Organizational">LDCX</creatorName>
    #       </creator>
    #     </creator>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'LDCX',
            nameType: 'Organizational'
          }
        ]
      )
    end
  end

  describe 'Cited contributor and uncited contributor with Conference role' do
    # Authors to include in citation
    ## Jane Stanford. Speaker.
    # Additional contributors
    ## LDCX. Conference.

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
                value: 'Speaker',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'speaker',
                code: 'spk',
                uri: 'http://id.loc.gov/vocabulary/relators/spk',
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
                value: 'LDCX'
              }
            ],
            type: 'conference',
            role: [
              {
                value: 'Conference',
                source: {
                  value: 'H2 contributor role terms'
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
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <contributors>
    #       <contributor contributorType="Other">
    #         <contributorName nameType="Organizational">LDCX</contributorName>
    #       </contributor>
    #     </contributors>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'LDCX',
            nameType: 'Organizational',
            contributorType: 'Other'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with Funder role' do
    # Authors to include in citation
    ## Stanford University. Funder.

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

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford University',
            nameType: 'Organizational'
          }
        ]
      )
    end

    it 'populates funder attributes correctly' do
      expect(funder_attributes).to eq(
        [
          {
            funderName: 'Stanford University'
          }
        ]
      )
    end
  end

  describe 'Cited contributor and uncited contributor with Funder role' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Funder.

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
                value: 'Data collector',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'compiler',
                code: 'com',
                uri: 'http://id.loc.gov/vocabulary/relators/com',
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
            ],
            note: [
              {
                type: 'citation status',
                value: 'false'
              }
            ]
          }
        ]
      }
    end

    # let(:datacite_xml) do
    #   # maps to fundingReferences if DataCite Funder
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <fundingReferences>
    #       <fundingReference>
    #         <funderName>Stanford University</funderName>
    #       </fundingReference>
    #     <fundingReferences>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq([])
    end

    it 'populates funder attributes correctly' do
      expect(funder_attributes).to eq(
        [
          {
            funderName: 'Stanford University'
          }
        ]
      )
    end
  end

  describe 'Cited contributor with Publisher role' do
    # Authors to include in citation
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

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
        ],
        event: [
          {
            type: 'publication',
            contributor: [
              {
                name: [
                  {
                    value: 'Stanford University Press'
                  }
                ],
                type: 'organization',
                role: [
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
        ]
      }
    end

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Organizational">Stanford University Press</creatorName>
    #       </creator>
    #     </creators>
    #     <publisher>Stanford Digital Repository</publisher>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford University Press',
            nameType: 'Organizational'
          }

        ]
      )
    end
  end

  describe 'Cited contributor and uncited contributor with Publisher role' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

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
          }
        ],
        event: [
          {
            type: 'publication',
            contributor: [
              {
                name: [
                  {
                    value: 'Stanford University Press'
                  }
                ],
                type: 'organization',
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
                ],
                note: [
                  {
                    type: 'citation status',
                    value: 'false'
                  }
                ]
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
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #       </creator>
    #     </creators>
    #     <contributors>
    #       <contributor contributorType="Distributor">
    #         <contributorName nameType="Organizational">Stanford University Press</contributorName>
    #       </contributor>
    #     </contributors>
    #     <publisher>Stanford Digital Repository</publisher>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford'
          }
        ]
      )
    end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'Stanford University Press',
            nameType: 'Organizational',
            contributorType: 'Distributor'
          }
        ]
      )
    end
  end

  describe 'Creator with ORCID' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## ORCID: 0000-0000-0000-0000
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

    # let(:datacite_xml) do
    #   <<~XML
    #     <creators>
    #       <creator>
    #         <creatorName nameType="Personal">Stanford, Jane</creatorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #         <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
    #       </creator>
    #     </creators>
    #   XML
    # end

    it 'populates creator attributes correctly' do
      expect(creator_attributes).to eq(
        [
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
        ]
      )
    end
  end

  describe 'Contributor with ORCID' do
    # Additional contributors
    ## Jane Stanford. Contributing author.
    ## ORCID: 0000-0000-0000-0000
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
                value: 'Contributing author',
                source: {
                  value: 'H2 contributor role terms'
                }
              },
              {
                value: 'contributor',
                code: 'ctb',
                uri: 'http://id.loc.gov/vocabulary/relators/aut',
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

    # let(:datacite_xml) do
    #   <<~XML
    #     <contributors>
    #       <contributor contributorType="Other">
    #         <contributorName nameType="Personal">Stanford, Jane</contributorName>
    #         <givenName>Jane</givenName>
    #         <familyName>Stanford</familyName>
    #         <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
    #       </contributor>
    #     </contributors>
    #   XML
    # end

    it 'populates contributor attributes correctly' do
      expect(contributor_attributes).to eq(
        [
          {
            name: 'Stanford, Jane',
            nameType: 'Personal',
            givenName: 'Jane',
            familyName: 'Stanford',
            contributorType: 'Other',
            nameIdentifiers: [
              {
                nameIdentifier: '0000-0000-0000-0000',
                nameIdentifierScheme: 'ORCID',
                schemeURI: 'https://orcid.org'
              }
            ]
          }
        ]
      )
    end
  end
end
