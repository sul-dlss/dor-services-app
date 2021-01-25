# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Contributor do
  # h2 mapping specification examples
  # from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/h2_cocina_mappings/h2_to_cocina_contributor.txt

  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.7',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd') do
        described_class.write(xml: xml, contributors: contributors, titles: nil, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  let(:mods_element_open) do
    <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.7"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
    XML
  end
  let(:mods_element_close) { '</mods>' }
  let(:stanford_self_deposit_source) do
    {
      value: 'Stanford self-deposit contributor types'
    }
  end
  let(:marc_relator_source) do
    {
      code: 'marcrelator',
      uri: 'http://id.loc.gov/vocabulary/relators/'
    }
  end
  let(:datacite_properties) do
    {
      value: 'DataCite properties'
    }
  end
  let(:datacite_contributor_types) do
    {
      value: 'DataCite contributor types'
    }
  end
  let(:datacite_creator_role) do
    Cocina::Models::DescriptiveValue.new(
      value: 'Creator',
      source: { value: 'DataCite properties' }
    )
  end
  let(:author_roles) do
    [
      {
        value: 'Author',
        source: stanford_self_deposit_source
      },
      {
        value: 'author',
        code: 'aut',
        uri: 'http://id.loc.gov/vocabulary/relators/aut',
        source: marc_relator_source
      },
      datacite_creator_role
    ]
  end
  let(:sponsor_roles) do
    [
      {
        value: 'Sponsor',
        source: stanford_self_deposit_source
      },
      Cocina::Models::DescriptiveValue.new(
        value: 'sponsor',
        code: 'spn',
        uri: 'http://id.loc.gov/vocabulary/relators/spn',
        source: marc_relator_source
      ),
      Cocina::Models::DescriptiveValue.new(
        value: 'Sponsor',
        source: { value: 'DataCite contributor types' }
      )
    ]
  end
  let(:publisher_roles) do
    [
      {
        value: 'Publisher',
        source: stanford_self_deposit_source
      },
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
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          role: [
            {
              value: 'Data collector',
              source: stanford_self_deposit_source
            },
            Cocina::Models::DescriptiveValue.new(
              value: 'compiler',
              code: 'com',
              uri: 'http://id.loc.gov/vocabulary/relators/com',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'DataCollector',
              source: datacite_contributor_types
            )
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
          <name type="personal" usage="primary">
            <namePart>Stanford, Jane</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">com</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/com">compiler</roleTerm>
            </role>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # example 2 from h2_to_cocina_contributor.txt
  context 'with person with multiple roles, one maps to DataCite creator property' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          role: [
            {
              value: 'Author',
              source: stanford_self_deposit_source
            },
            {
              value: 'Principal investigator',
              source: stanford_self_deposit_source
            },
            Cocina::Models::DescriptiveValue.new(
              value: 'author',
              code: 'aut',
              uri: 'http://id.loc.gov/vocabulary/relators/aut',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'research team head',
              code: 'rth',
              uri: 'http://id.loc.gov/vocabulary/relators/rth',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'Creator',
              source: datacite_properties
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'ProjectLeader',
              source: datacite_contributor_types
            )
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 3 from h2_to_cocina_contributor.txt
  context 'with organization with single role' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'Host institution',
              source: stanford_self_deposit_source
            },
            Cocina::Models::DescriptiveValue.new(
              value: 'host institution',
              code: 'his',
              uri: 'http://id.loc.gov/vocabulary/relators/his',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'HostingInstitution',
              source: datacite_contributor_types
            )
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
          <name type="corporate" usage="primary">
            <namePart>Stanford University</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">his</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/his">host institution</roleTerm>
            </role>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # example 4 from h2_to_cocina_contributor.txt
  context 'with organization with multiple roles' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'Sponsor',
              source: stanford_self_deposit_source
            },
            Cocina::Models::DescriptiveValue.new(
              value: 'sponsor',
              code: 'spn',
              uri: 'http://id.loc.gov/vocabulary/relators/spn',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'Sponsor',
              source: datacite_contributor_types
            ),
            {
              value: 'Issuing body',
              source: stanford_self_deposit_source
            },
            Cocina::Models::DescriptiveValue.new(
              value: 'issuing body',
              code: 'isb',
              uri: 'http://id.loc.gov/vocabulary/relators/isb',
              source: marc_relator_source
            ),
            Cocina::Models::DescriptiveValue.new(
              value: 'Distributor',
              source: datacite_contributor_types
            )
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 5 from h2_to_cocina_contributor.txt
  context 'with conference as contributor' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [{ value: 'LDCX' }],
          type: 'conference',
          status: 'primary',
          role: [
            {
              value: 'Conference',
              source: stanford_self_deposit_source
            }
          ]
        )
      ]
    end
    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          value: 'Event',
          type: 'resource types',
          source: {
            value: 'DataCite resource types'
          }
        )
      ]
    end
    let(:druid) { 'druid:oo111oo2222' }
    let(:descriptive) { Cocina::Models::Description.new({ contributor: contributors, form: forms }, false, false) }

    it 'builds the expected xml' do
      # NOTE: conference does NOT get a role because 'conference' is a MODS name type
      result_xml = Cocina::ToFedora::Descriptive.transform(descriptive, druid).to_xml
      expect(result_xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        <name type="conference" usage="primary">
          <namePart>LDCX</namePart>
        </name>
        #{mods_element_close}
      XML
    end
  end

  # example 6 from h2_to_cocina_contributor.txt
  context 'with event as contributor' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [{ value: 'San Francisco Symphony Concert' }],
          type: 'event',
          status: 'primary',
          role: [
            {
              value: 'Event',
              source: stanford_self_deposit_source
            }
          ]
        )
      ]
    end
    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          value: 'Event',
          type: 'resource types',
          source: {
            value: 'DataCite resource types'
          }
        )
      ]
    end
    let(:druid) { 'druid:oo111oo2222' }
    let(:descriptive) { Cocina::Models::Description.new({ contributor: contributors, form: forms }, false, false) }

    it 'builds the expected xml' do
      # NOTE: event does get a role because 'event' is NOT a MODS name type
      result_xml = Cocina::ToFedora::Descriptive.transform(descriptive, druid).to_xml
      expect(result_xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        <name type="corporate" usage="primary">
          <namePart>San Francisco Symphony Concert</namePart>
          <role>
            <roleTerm type="text">Event</roleTerm>
          </role>
        </name>
        #{mods_element_close}
      XML
    end
  end

  # example 7 from h2_to_cocina_contributor.txt
  context 'with multiple person contributors' do
    # TODO: implement order
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        ),
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Leland',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          # order: 2,
          role: author_roles
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 8 from h2_to_cocina_contributor.txt
  context 'with multiple contributors - person and organization' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          role: author_roles
        ),
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          role: sponsor_roles
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 9 from h2_to_cocina_contributor.txt
  context 'with multipe person contributors and organization as author' do
    # TODO: implement order
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        ),
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          # order: 2,
          role: author_roles
        ),
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Leland',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          # order: 3,
          role: author_roles
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 10 from h2_to_cocina_contributor.txt
  context 'with multipe person contributors and organization as non-author' do
    # TODO: implement order
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Jane',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          status: 'primary',
          # order: 1,
          role: author_roles
        ),
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          role: sponsor_roles
        ),
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Stanford, Leland',
              type: 'inverted full name'
            }
          ],
          type: 'person',
          # order: 2,
          role: author_roles
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # example 11 from h2_to_cocina_contributor.txt
  context 'with organization as funder' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [{ value: 'Stanford University' }],
          type: 'organization',
          status: 'primary',
          role: [
            {
              value: 'Funder',
              source: stanford_self_deposit_source
            },
            {
              value: 'funder',
              code: 'fnd',
              uri: 'http://id.loc.gov/vocabulary/relators/fnd',
              source: marc_relator_source
            }
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        <name type="corporate" usage="primary">
          <namePart>Stanford University</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/fnd">fnd</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/fnd">funder</roleTerm>
          </role>
        </name>
        #{mods_element_close}
      XML
    end
  end

  # example 12 from h2_to_cocina_contributor.txt
  context 'with publisher and publication date entered by H2 user' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end
    let(:druid) { 'druid:oo111oo2222' }
    let(:descriptive) { Cocina::Models::Description.new({ event: events }, false, false) }

    it 'builds the expected xml' do
      result_xml = Cocina::ToFedora::Descriptive.transform(descriptive, druid).to_xml
      expect(result_xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        <originInfo eventType="publication">
          <publisher>Stanford University Press</publisher>
          <dateIssued keyDate="yes" encoding="w3cdtf">2020-02-14</dateIssued>
        </originInfo>
        #{mods_element_close}
      XML
    end
  end

  # example 13 from h2_to_cocina_contributor.txt
  context 'with publisher entered by user' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          type: 'publication',
          contributor: [
            {
              name: [{ value: 'Stanford University Press' }],
              type: 'organization',
              role: publisher_roles
            }
          ]
        )
      ]
    end
    let(:druid) { 'druid:oo111oo2222' }
    let(:descriptive) { Cocina::Models::Description.new({ event: events }, false, false) }

    it 'builds the expected xml' do
      result_xml = Cocina::ToFedora::Descriptive.transform(descriptive, druid).to_xml
      expect(result_xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        <originInfo eventType="publication">
          <publisher>Stanford University Press</publisher>
        </originInfo>
        #{mods_element_close}
      XML
    end
  end
end
