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
                            access: cocina_access)
  end
  let(:mapped_to_datacite) { described_class.new(cocina_item) }
  let(:mapped_datacite_creators) { mapped_to_datacite.creators }
  let(:mapped_datacite_contributrors) { mapped_to_datacite.contributors }
  let(:mapped_datacite_funding_references) { mapped_to_datacite.funding_references }

  context 'when part 1 of name or affiliation has ROR; part 2 may or may not be entered' do
    # NOTE: Per conversation with Amy 7/7/23, if part 1 of name or affiliation has ROR, drop part 2 if entered. Otherwise the
    # value would need to be mapped twice, once with the ROR and once with the more specific department, as the ROR
    # applies only to the institution.
    context 'when cited contributor with affiliation' do
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
          creator: {
            creatorName: {
              nameType: 'Personal',
              value: 'Smith, Jane'
            },
            givenName: 'Jane',
            familyName: 'Smith',
            affiliation: [
              {
                affiliationIdentifier: 'https://ror.org/00f54p054',
                affiliationIdentifierScheme: 'ROR',
                schemeURI: 'https://ror.org',
                value: 'Stanford University'
              }
            ]
          }
        ]
      end
      let(:expected_xml) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Smith, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Smith</familyName>
              <affiliation affiliationIdentifier="https://ror.org/00f54p054" affiliationIdentifierScheme="ROR" schemeURI="https://ror.org">Stanford University</affiliation>
            </creator>
          </creators>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_creators.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when cited organizational creator with identifier' do
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
      let(:expected_xml) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University</creatorName>
              <nameIdentifier nameIdentifierScheme="ROR" schemeURI="https://ror.org">https://ror.org/00f54p054</nameIdentifier>
            </creator>
          </creators>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_creators.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when uncited contributor with affiliation and H2 role "Thesis advisor"' do
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
              nameType: 'Personal',
              value: 'Smith, Jane'
            },
            givenName: 'Jane',
            familyName: 'Smith',
            affiliation: [
              {
                affiliationIdentifier: 'https://ror.org/00f54p054',
                affiliationIdentifierScheme: 'ROR',
                schemeURI: 'https://ror.org',
                value: 'Stanford University'
              }
            ]
          }
        ]
      end
      let(:expected_xml) do
        <<~XML
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Personal">Smith, Jane</contributorName>
              <givenName>Jane</givenName>
              <familyName>Smith</familyName>
              <affiliation affiliationIdentifier="https://ror.org/00f54p054" affiliationIdentifierScheme="ROR" schemeURI="https://ror.org">Stanford University</affiliation>
            </contributor>
          </contributors>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_contributors.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when uncited organizational contributor with identifier and H2 role "Degree granting institution"' do
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
      let(:expected_xml) do
        <<~XML
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Organizational">Stanford University</contributorName>
              <nameIdentifier nameIdentifierScheme="ROR" schemeURI="https://ror.org">https://ror.org/00f54p054</nameIdentifier>
            </contributor>
          </contributors>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_contributors.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when uncited organizational contributor with identifier and H2 role "Funder"' do
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
      let(:expected_xml) do
        <<~XML
          <fundingReferences>
            <fundingReference>
              <funderName>Stanford University</funderName>
              <funderIdentifier funderIdentifierType="ROR" schemeURI="https://ror.org">https://ror.org/00f54p054</funderIdentifier>
            </fundingReference>
          <fundingReferences>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_funding_references.to_xml).to be_equivalent_to_xml(expected_xml)
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
              something: 'something'
            }
          ]
        }
      end
      let(:expected_hash) do
        [
          creator: {
            creatorName: {
              nameType: 'Personal',
              value: 'Smith, Jane'
            },
            givenName: 'Jane',
            familyName: 'Smith',
            affiliation: [
              {
                value: 'Stanford University, Woods Institute'
              }
            ]
          }
        ]
      end
      let(:expected_xml) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Personal">Smith, Jane</creatorName>
              <givenName>Jane</givenName>
              <familyName>Smith</familyName>
              <affiliation>Stanford University, Woods Institute</affiliation>
            </creator>
          </creators>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_creators.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when cited organizational contributor' do
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
      let(:expected_xml) do
        <<~XML
          <creators>
            <creator>
              <creatorName nameType="Organizational">Stanford University, Woods Institute</creatorName>
            </creator>
          </creators>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_creators).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_creators.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when uncited contributor with affiliation and H2 role "Thesis advisor"' do
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
              nameType: 'Personal',
              value: 'Smith, Jane'
            },
            givenName: 'Jane',
            familyName: 'Smith',
            affiliation: [
              {
                value: 'Stanford University, Woods Institute'
              }
            ]
          }
        ]
      end
      let(:expected_xml) do
        <<~XML
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Personal">Smith, Jane</contributorName>
              <givenName>Jane</givenName>
              <familyName>Smith</familyName>
              <affiliation>Stanford University, Woods Institute</affiliation>
            </contributor>
          </contributors>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_contributors).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_contributors.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when uncited organizational contributor with H2 role "Degree granting institution"' do
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
      let(:expected_xml) do
        <<~XML
          <contributors>
            <contributor contributorType="Other">
              <contributorName nameType="Organizational">Stanford University, Woods Institute</contributorName>
            </contributor>
          </contributors>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_funding_references.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end

    context 'when cited or uncited organizational contributor with H2 role "Funder"' do
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
      let(:expected_xml) do
        <<~XML
          <fundingReferences>
            <fundingReference>
              <funderName>Stanford University, Woods Institute</funderName>
            </fundingReference>
          <fundingReferences>
        XML
      end

      it 'maps to the expected hash' do
        expect(mapped_datacite_funding_references).to eq expected_hash
      end

      it 'maps to the expected xml' do
        expect(mapped_datacite_funding_references.to_xml).to be_equivalent_to_xml(expected_xml)
      end
    end
  end
end
