# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite contributor mappings (H2 specific)' do
  describe 'Cited contributor with author role' do
    # Authors to include in citation
    ## Jane Stanford. Author.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Multiple cited contributors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## Leland Stanford. Author.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
              <creator>
                <creatorName nameType="Personal">Stanford, Leland</creatorName>
                <givenName>Leland</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
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
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with cited organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    ## Stanford University. Sponsor.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
              <creator>
                <creatorName nameType="Organizational">Stanford University</creatorName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
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
            }
          }
        }
      end
    end
  end

  describe 'Cited organization' do
    # Authors to include in citation
    ## Stanford University. Host institution.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">Stanford University</creatorName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford University',
                  nameType: 'Organizational'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Multiple cited organizations' do
    # Authors to include in citation
    ## Stanford University. Host institution.
    ## Department of English. Department.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">Stanford University</creatorName>
              </creator>
              <creator>
                <creatorName nameType="Organizational">Department of English</creatorName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford University',
                  nameType: 'Organizational'
                },
                {
                  name: 'Department of English',
                  nameType: 'Organizational'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited and uncited authors' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Leland Stanford. Contributing author.
    # Add contributor role to names in Additional contributors section.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <contributors>
              <contributor contributorType="Other">
                <contributorName nameType="Personal">Stanford, Leland</contributorName>
                <givenName>Leland</givenName>
                <familyName>Stanford</familyName>
              </contributor>
            </contributors>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              contributors: [
                {
                  name: 'Stanford, Leland',
                  nameType: 'Personal',
                  givenName: 'Leland',
                  familyName: 'Stanford',
                  contributorType: 'Other'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with uncited sponsoring organization' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Sponsor.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <contributors>
              <contributor contributorType="Sponsor">
                <contributorName nameType="Organizational">Stanford University</contributorName>
              </contributor>
            </contributors>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              contributors: [
                {
                  name: 'Stanford University',
                  nameType: 'Organizational',
                  contributorType: 'Sponsor'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with Event role' do
    # Authors to include in citation
    ## San Francisco Symphony Concert. Event.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">San Francisco Symphony Concert</creatorName>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'San Francisco Symphony Concert',
                  nameType: 'Organizational'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Event role' do
    # Authors to include in citation
    ## Jane Stanford. Event organizer.
    # Additional contributors
    ## San Francisco Symphony Concert. Event.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <contributors>
              <contributor contributorType="Other">
                <contributorName nameType="Organizational">San Francisco Symphony Concert</contributorName>
              </contributor>
            </contributors>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              contributors: [
                {
                  name: 'San Francisco Symphony Concert',
                  nameType: 'Organizational',
                  contributorType: 'Other'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with Conference role' do
    # Authors to include in citation
    ## LDCX. Conference.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">LDCX</creatorName>
              </creator>
            </creator>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'LDCX',
                  nameType: 'Organizational'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Conference role' do
    # Authors to include in citation
    ## Jane Stanford. Speaker.
    # Additional contributors
    ## LDCX. Conference.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <contributors>
              <contributor contributorType="Other">
                <contributorName nameType="Organizational">LDCX</contributorName>
              </contributor>
            </contributors>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              contributors: [
                {
                  name: 'LDCX',
                  nameType: 'Organizational',
                  contributorType: 'Other'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with Funder role' do
    # Authors to include in citation
    ## Stanford University. Funder.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">Stanford University</creatorName>
              </creator>
            </creators>
            <fundingReferences>
              <fundingReference>
                <funderName>Stanford University</funderName>
              </fundingReference>
            <fundingReferences>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford University',
                  nameType: 'Organizational'
                }
              ],
              fundingReferences: [
                {
                  funderName: 'Stanford University'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Funder role' do
    # Authors to include in citation
    ## Jane Stanford. Data collector.
    # Additional contributors
    ## Stanford University. Funder.

    xit 'not implemented' do
      let(:mods) do
        # maps to fundingReferences if DataCite Funder
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <fundingReferences>
              <fundingReference>
                <funderName>Stanford University</funderName>
              </fundingReference>
            <fundingReferences>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              fundingReferences: [
                {
                  funderName: 'Stanford University'
                }
              ]
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor with Publisher role' do
    # Authors to include in citation
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">Stanford University Press</creatorName>
              </creator>
            </creators>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford University Press',
                  nameType: 'Organizational'
                }
              ],
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end

  describe 'Cited contributor and uncited contributor with Publisher role' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    # Additional contributors
    ## Stanford University Press. Publisher.
    # For DataCite output, publisher is always Stanford Digital Repository.

    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
              </creator>
            </creators>
            <contributors>
              <contributor contributorType="Distributor">
                <contributorName nameType="Organizational">Stanford University Press</contributorName>
              </contributor>
            </contributors>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford, Jane',
                  nameType: 'Personal',
                  givenName: 'Jane',
                  familyName: 'Stanford'
                }
              ],
              contributors: [
                {
                  name: 'Stanford University Press',
                  nameType: 'Organizational',
                  contributorType: 'Distributor'
                }
              ],
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end

  describe 'Creator with ORCID' do
    # Authors to include in citation
    ## Jane Stanford. Author.
    ## ORCID: 0000-0000-0000-0000
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Personal">Stanford, Jane</creatorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
                <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
              </creator>
            </creators>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
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
              ]
            }
          }
        }
      end
    end
  end

  describe 'Contributor with ORCID' do
    # Additional contributors
    ## Jane Stanford. Contributing author.
    ## ORCID: 0000-0000-0000-0000
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <contributors>
              <contributor contributorType="Other">
                <contributorName nameType="Personal">Stanford, Jane</contributorName>
                <givenName>Jane</givenName>
                <familyName>Stanford</familyName>
                <nameIdentifier nameIdentifierScheme="ORCID" schemeURI="https://orcid.org">0000-0000-0000-0000</nameIdentifier>
              </contributor>
            </contributors>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              contributors: [
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
            }
          }
        }
      end
    end
  end
end
