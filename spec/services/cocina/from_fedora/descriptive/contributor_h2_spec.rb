# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
  # h2 mapping specification examples
  # from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/h2_cocina_mappings/h2_to_cocina_contributor.txt
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end
  let(:marc_relator_source) do
    {
      code: 'marcrelator',
      uri: 'http://id.loc.gov/vocabulary/relators/'
    }
  end
  let(:author_roles) do
    [
      {
        value: 'author',
        code: 'aut',
        uri: 'http://id.loc.gov/vocabulary/relators/aut',
        source: marc_relator_source
      }
    ]
  end
  let(:sponsor_roles) do
    [
      {
        value: 'sponsor',
        code: 'spn',
        uri: 'http://id.loc.gov/vocabulary/relators/spn',
        source: marc_relator_source
      }
    ]
  end
  let(:publisher_roles) do
    [
      {
        value: 'publisher',
        code: 'pbl',
        uri: 'http://id.loc.gov/vocabulary/relators/pbl',
        source: marc_relator_source
      }
    ]
  end

  # example 1 from h2_to_cocina_contributor.txt
  context 'with person with single role' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          role: [
            {
              value: 'compiler',
              code: 'com',
              uri: 'http://id.loc.gov/vocabulary/relators/com',
              source: marc_relator_source
            }
          ]
        }
      ]
    end
  end

  # example 2 from h2_to_cocina_contributor.txt
  context 'with person with multiple roles, one maps to DataCite creator property' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/rth">rth</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/rth">research team head</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          role: [
            {
              value: 'author',
              code: 'aut',
              uri: 'http://id.loc.gov/vocabulary/relators/aut',
              source: marc_relator_source
            },
            {
              value: 'research team head',
              code: 'rth',
              uri: 'http://id.loc.gov/vocabulary/relators/rth',
              source: marc_relator_source
            }
          ]
        }
      ]
    end
  end

  # example 3 from h2_to_cocina_contributor.txt
  context 'with organization with single role' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'host institution',
              code: 'his',
              uri: 'http://id.loc.gov/vocabulary/relators/his',
              source: marc_relator_source
            }
          ]
        }
      ]
    end
  end

  # example 4 from h2_to_cocina_contributor.txt
  context 'with organization with multiple roles' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
          </role>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/isb">isb</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/isb">issuing body</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'sponsor',
              code: 'spn',
              uri: 'http://id.loc.gov/vocabulary/relators/spn',
              source: marc_relator_source
            },
            {
              value: 'issuing body',
              code: 'isb',
              uri: 'http://id.loc.gov/vocabulary/relators/isb',
              source: marc_relator_source
            }
          ]
        }
      ]
    end
  end

  # example 5 from h2_to_cocina_contributor.txt
  context 'with conference as contributor' do
    let(:xml) do
      <<~XML
        <name type="conference" usage="primary">
          <namePart>LDCX</namePart>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'LDCX' }],
          type: 'conference',
          status: 'primary'
        }
      ]
    end
  end

  # old example 6 from h2_to_cocina_contributor.txt
  context 'with event as contributor' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>San Francisco Symphony Concert</namePart>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'San Francisco Symphony Concert' }],
          type: 'organization',
          status: 'primary'
        }
      ]
    end
  end

  # example 6 from h2_to_cocina_contributor.txt
  context 'with event as contributor with role' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>San Francisco Symphony Concert</namePart>
          <role>
            <roleTerm type="text">Event</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      # NOTE: from the DSA app, there is not enough context to make the cocina type "event" (?)
      expect(build).to eq [
        {
          name: [{ value: 'San Francisco Symphony Concert' }],
          type: 'organization',
          status: 'primary',
          role: [{ value: 'Event' }]
        }
      ]
    end
  end

  # example 7 from h2_to_cocina_contributor.txt
  context 'with multiple person contributors' do
    # TODO: implement order
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
        <name type="personal">
          <namePart>Stanford, Leland</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        },
        {
          name: [{ value: 'Stanford, Leland' }],
          type: 'person',
          # order: 2,
          role: author_roles
        }
      ]
    end
  end

  # example 8 from h2_to_cocina_contributor.txt
  context 'with multiple contributors - person and organization' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
        <name type="corporate">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          role: author_roles
        },
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          role: sponsor_roles
        }
      ]
    end
  end

  # example 9 from h2_to_cocina_contributor.txt
  context 'with multipe person contributors and organization as author' do
    # TODO: implement order
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
        <name type="corporate">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
        <name type="personal">
          <namePart>Stanford, Leland</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        },
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          # order: 2,
          role: author_roles
        },
        {
          name: [{ value: 'Stanford, Leland' }],
          type: 'person',
          # order: 3,
          role: author_roles
        }
      ]
    end
  end

  # example 10 from h2_to_cocina_contributor.txt
  context 'with multipe person contributors and organization as non-author' do
    # TODO: implement order
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Stanford, Jane</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
        <name type="corporate">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/spn">sponsor</roleTerm>
          </role>
        </name>
        <name type="personal">
          <namePart>Stanford, Leland</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford, Jane' }],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        },
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          # order: 2,
          role: sponsor_roles
        },
        {
          name: [{ value: 'Stanford, Leland' }],
          type: 'person',
          # order: 3,
          role: author_roles
        }
      ]
    end
  end

  # example 11 from h2_to_cocina_contributor.txt
  context 'with organization as funder' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/fnd">fnd</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/fnd">funder</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'funder',
              code: 'fnd',
              uri: 'http://id.loc.gov/vocabulary/relators/fnd',
              source: marc_relator_source
            }
          ]
        }
      ]
    end
  end

  # example 12 from h2_to_cocina_contributor.txt
  context 'with publisher and publication date entered by H2 user' do
    let(:xml) do
      <<~XML
        <titleInfo>
          <title>Foo</title>
        </titleInfo>
        <originInfo eventType="publication">
          <publisher>Stanford University Press</publisher>
          <dateIssued keyDate="yes" encoding="w3cdtf">2020-02-14</dateIssued>
        </originInfo>
      XML
    end
    let(:descriptive) { Cocina::FromFedora::Descriptive.props(mods: ng_xml) }

    it 'builds the expected cocina data structure' do
      expect(descriptive).to eq(
        {
          title: [{ value: 'Foo' }],
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [{ value: 'Stanford University Press' }],
                  type: 'organization',
                  role: publisher_roles
                }
              ],
              date: [
                {
                  encoding: { code: 'w3cdtf' },
                  value: '2020-02-14',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      )
    end
  end

  # example 13 from h2_to_cocina_contributor.txt
  context 'with publisher entered by user' do
    let(:xml) do
      <<~XML
        <titleInfo>
          <title>Foo</title>
        </titleInfo>
        <originInfo eventType="publication">
          <publisher>Stanford University Press</publisher>
        </originInfo>
      XML
    end
    let(:descriptive) { Cocina::FromFedora::Descriptive.props(mods: ng_xml) }

    it 'builds the expected cocina data structure' do
      # expect(descriptive[:events]).to match_array [

      expect(descriptive).to eq(
        {
          title: [{ value: 'Foo' }],
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [{ value: 'Stanford University Press' }],
                  type: 'organization',
                  role: publisher_roles
                }
              ]
            }
          ]
        }
      )
    end
  end
end
