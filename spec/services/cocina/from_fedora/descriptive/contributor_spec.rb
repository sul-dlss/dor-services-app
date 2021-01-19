# frozen_string_literal: true

require 'rails_helper'

# numbered examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt
RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new(notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  # 1. Personal name
  context 'with a personal name' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Dunnett, Dorothy</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Dunnett, Dorothy'
            }
          ],
          "type": 'person',
          "status": 'primary'
        }
      ]
    end
  end

  # 2. Corporate name
  context 'with a corporate name' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Dorothy L. Sayers Society</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Dorothy L. Sayers Society'
            }
          ],
          "type": 'organization',
          "status": 'primary'
        }
      ]
    end
  end

  # 3. Family name
  context 'with a family name' do
    let(:xml) do
      <<~XML
        <name type="family" usage="primary">
          <namePart>James family</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'James family'
            }
          ],
          "type": 'family',
          "status": 'primary'
        }
      ]
    end
  end

  # 4. Conference name
  context 'with a conference name' do
    let(:xml) do
      <<~XML
        <name type="conference" usage="primary">
          <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Mystery Science Theater ConventioCon Expo Fest-o-rama'
            }
          ],
          "type": 'conference',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with an invalid type' do
    context 'when miscapitalized' do
      let(:xml) do
        <<~XML
          <name type="Personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "type": 'person',
            "status": 'primary'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name type incorrectly capitalized', { type: 'Personal' })
      end
    end

    context 'when unrecognized' do
      let(:xml) do
        <<~XML
          <name type="primary">
            <namePart>Vickery, Claire</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Vickery, Claire'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('Name type unrecognized', { type: 'primary' })
      end
    end
  end

  context 'with empty type attribute and other empty goodness' do
    let(:xml) do
      <<~XML
        <name type="">
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="code" valueURI=""/>
            <role>
        </name>
      XML
    end

    before do
      allow(notifier).to receive(:warn).exactly(3).times
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [{}]
      expect(notifier).to have_received(:warn).with('name type attribute is set to ""')
      expect(notifier).to have_received(:warn).with('name/namePart missing value')
      expect(notifier).to have_received(:warn).with('Missing name/namePart element')
    end
  end

  # 5. Name with additional subelements
  context 'with additional subelements' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart type="termsOfAddress">Dr.</namePart>
          <namePart type="given">Terry</namePart>
          <namePart type="family">Castle</namePart>
          <namePart type="date">1953-</namePart>
          <affiliation>Stanford University</affiliation>
          <nameIdentifier type="wikidata">https://www.wikidata.org/wiki/Q7704207</nameIdentifier>
          <displayForm>Castle, Terry</displayForm>
          <description>Professor of English</description>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'Dr.',
                  "type": 'term of address'
                },
                {
                  "value": 'Terry',
                  "type": 'forename'
                },
                {
                  "value": 'Castle',
                  "type": 'surname'
                },
                {
                  "value": '1953-',
                  "type": 'life dates'
                }
              ]
            },
            {
              "value": 'Castle, Terry',
              "type": 'display'
            }
          ],
          "status": 'primary',
          "type": 'person',
          "identifier": [
            {
              "value": 'https://www.wikidata.org/wiki/Q7704207',
              "type": 'Wikidata'
            }
          ],
          "note": [
            {
              "value": 'Stanford University',
              "type": 'affiliation'
            },
            {
              "value": 'Professor of English',
              "type": 'description'
            }
          ]
        }
      ]
    end
  end

  # 5b. Name with untyped nameIdentifier
  context 'with missing nameIdentifier type' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Burnett, Michael W.</namePart>
          <nameIdentifier>https://orcid.org/0000-0001-5126-5568</nameIdentifier>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          identifier: [
            {
              value: 'https://orcid.org/0000-0001-5126-5568'
            }
          ],
          name: [
            {
              value: 'Burnett, Michael W.'
            }
          ],
          type: 'person'
        }
      ]
    end
  end

  context 'with namePart with empty type attribute' do
    context 'without role' do
      let(:xml) do
        <<~XML
          <name type="personal" authority="local">
            <namePart type="">Burke, Andy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure without structuredValue and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Burke, Andy',
                "source": {
                  "code": 'local'
                }
              }
            ],
            "type": 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name/namePart type attribute set to ""')
      end
    end

    context 'with an invalid type on the namePart node' do
      let(:xml) do
        <<~XML
          <name>
            <namePart type="personal">Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure without structuredValue and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('namePart has unknown type assigned', { type: 'personal' })
      end
    end
  end

  # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
  context 'with missing nameIdentifier type' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Burnett, Michael W.</namePart>
          <nameIdentifier>https://orcid.org/0000-0001-5126-5568</nameIdentifier>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          identifier: [
            {
              value: 'https://orcid.org/0000-0001-5126-5568'
            }
          ],
          name: [
            {
              value: 'Burnett, Michael W.'
            }
          ],
          type: 'person'
        }
      ]
    end
  end

  # 5c. Name with multiple untyped parts
  context 'with multiple untyped parts' do
    let(:xml) do
      <<~XML
        <name type="corporate">
          <namePart>United States</namePart>
          <namePart>Office of Foreign Investment in the United States.</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'United States'
                },
                {
                  "value": 'Office of Foreign Investment in the United States.'
                }
              ]
            }
          ],
          "type": 'organization'
        }
      ]
    end
  end

  context 'when namePart with type but no value' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Kielmansegg, Erich Ludwig Friedrich Christian</namePart>
          <namePart type="termsOfAddress">Graf von</namePart>
          <namePart type="date">1847-1923</namePart>
          <namePart type="date"/>
        </name>
      XML
    end

    before do
      allow(notifier).to receive(:warn).once
    end

    it 'ignores the namePart with no value and warns' do
      expect(build).to eq [{ name: [{ structuredValue: [{ value: 'Kielmansegg, Erich Ludwig Friedrich Christian' },
                                                        { type: 'term of address', value: 'Graf von' },
                                                        { type: 'life dates', value: '1847-1923' }] }],
                             type: 'person' }]
      expect(notifier).to have_received(:warn).with('name/namePart missing value')
    end
  end

  # 6. Name with ordinal
  context 'with ordinal' do
    xit 'TODO: 6. Name with ordinal - mods_to_cocina_name.txt#L137'
  end

  context 'with role' do
    # 7. Name with role
    context 'when roleTerm for types code and text' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "status": 'primary',
            "type": 'person',
            "role": [
              {
                "value": 'author',
                "code": 'aut',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
                "source": {
                  "code": 'marcrelator',
                  "uri": 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      end
    end

    context 'with empty roleTerm' do
      let(:xml) do
        <<~XML
          <name type="personal" authority="local">
            <namePart type="">Burke, Andy</namePart>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds cocina data structure, ignoring the namePart with no value and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Burke, Andy',
                "source": {
                  "code": 'local'
                }
              }
            ],
            "type": 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name/namePart type attribute set to ""')
        expect(notifier).to have_received(:warn).with('name/role/roleTerm missing value')
      end
    end

    # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
    context 'with a role that has no URI and has xlink uris from MODS 3.3' do
      # MODS 3.3 header from druid:yy910cj7795
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns="http://www.loc.gov/mods/v3" version="3.3"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
            <name type="personal" authority="naf" xlink:href="http://id.loc.gov/authorities/names/n82087745">
              <role>
                <roleTerm>creator</roleTerm>
              </role>
              <namePart>Tirion, Isaak</namePart>
            </name>
          </mods>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Tirion, Isaak',
                uri: 'http://id.loc.gov/authorities/names/n82087745',
                source: {
                  code: 'naf'
                }
              }
            ],
            role: [
              {
                "value": 'creator'
              }
            ],
            type: 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name has an xlink:href property')
      end
    end

    # 7b. Role text only
    context 'when roleTerm is type text' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "status": 'primary',
            "type": 'person',
            "role": [
              {
                "value": 'author',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
                "source": {
                  "code": 'marcrelator',
                  "uri": 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      end
    end

    context 'when roleTerm for type text is incorrectly capitalized' do
      let(:xml) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University. School of Engineering</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">Sponsor</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure with downcased role' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Stanford University. School of Engineering'
              }
            ],
            status: 'primary',
            type: 'organization',
            role: [
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
      end
    end

    # 7c. Role code only
    context 'when roleTerm is type code' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "status": 'primary',
            "type": 'person',
            "role": [
              {
                "code": 'aut',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
                "source": {
                  "code": 'marcrelator',
                  "uri": 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      end
    end

    # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
    context 'when the role code is missing the authority and length is 3' do
      let(:xml) do
        <<~XML
          <name>
            <namePart>Selective Service System</namePart>
            <role>
              <roleTerm type="code">isb</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          { name: [
            { value: 'Selective Service System' }
          ], role: [
            { code: 'isb' }
          ] }
        ]
        expect(notifier).to have_received(:warn).with('Contributor role code is missing authority')
      end
    end

    context 'when the role code is missing the authority and length is not 3' do
      let(:xml) do
        <<~XML
          <name valueURI="corporate">
            <namePart>Selective Service System</namePart>
            <role>
              <roleTerm type="code">isbx</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:error)
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and notifies error' do
        expect(build).to eq [
          { name: [
            { value: 'Selective Service System', uri: 'corporate' }
          ], role: [
            { code: 'isbx' }
          ] }
        ]
        expect(notifier).to have_received(:warn).with('Value URI has unexpected value', { uri: 'corporate' })
        expect(notifier).to have_received(:error).with('Contributor role code has unexpected value', { role: 'isbx' })
      end
    end

    # 7d. Role with valueURI as the only attribute
    context 'when role has valueURI as the only authority attribute' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'author',
                code: 'aut',
                uri: 'http://id.loc.gov/vocabulary/relators/aut'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('Contributor role code is missing authority')
      end
    end

    # 7e. Role with authority as the only authority attribute
    context 'when role has authority as the only authority attribute' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator">author</roleTerm>
              <roleTerm type="code" authority="marcrelator">aut</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'author',
                code: 'aut',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      end
    end

    # 7f. role without namePart value (it has an EMPTY namePart element)
    context 'when role without namePart value' do
      let(:xml) do
        <<~XML
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds empty cocina data structure and warns' do
        expect(build).to eq [{}]
        expect(notifier).to have_received(:warn).with('name/namePart missing value')
        expect(notifier).to have_received(:warn).with('Missing name/namePart element')
      end
    end

    context 'with missing namePart element' do
      let(:xml) do
        <<~XML
          <name>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">Sponsor</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [{}]
        expect(notifier).to have_received(:warn).with('Missing name/namePart element')
      end
    end

    # 7g. Role attribute without roleTerm or namePart value
    context 'when roleTerm with no value and no namepart' do
      let(:xml) do
        <<~XML
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds empty cocina data structure and warns' do
        expect(build).to eq [{}]
        expect(notifier).to have_received(:warn).with('name/namePart missing value')
      end
    end

    # 7h. Unauthorized role term only
    context 'when unauthorized role term only' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "type": 'person',
            "status": 'primary',
            "role": [
              {
                "value": 'author'
              }
            ]
          }
        ]
      end
    end

    # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
    context 'when multiple roles' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text">primary advisor</roleTerm>
              </role>
              <role>
                <roleTerm authority="marcrelator" type="code" authorityURI="http://id.loc.gov/vocabulary/relators/">ths</roleTerm>
              </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'primary advisor'
              },
              {
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                },
                code: 'ths'
              }
            ]
          }
        ]
      end
    end
  end

  # 8. Name with authority
  context 'with authority' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n79046044">
          <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          name: [
            {
              value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
              uri: 'http://id.loc.gov/authorities/names/n79046044',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ],
          status: 'primary',
          type: 'person'
        }
      ]
    end
  end

  # 9. Multiple names, one primary
  context 'with multiple names, one primary' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Bulgakov, Mikhail</namePart>
          <role>
            <roleTerm type="text">author</roleTerm>
          </role>
        </name>
        <name type="personal">
          <namePart>Burgin, Diana Lewis</namePart>
          <role>
            <roleTerm type="text">translator</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Bulgakov, Mikhail'
            }
          ],
          "type": 'person',
          "status": 'primary',
          "role": [
            {
              "value": 'author'
            }
          ]
        },
        {
          "name": [
            {
              "value": 'Burgin, Diana Lewis'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'translator'
            }
          ]
        }
      ]
    end
  end

  # FIXME: this example should be added to cdm ??? - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
  # kind of 18, except with multiple names
  context 'with multiple names, one primary, dates, no roles' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Sarmiento, Domingo Faustino</namePart>
          <namePart type="date">1811-1888</namePart>
        </name>
        <name type="personal">
          <namePart>Rojas, Ricardo</namePart>
          <namePart type="date">1882-1957</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            "structuredValue": [
              {
                "value": 'Sarmiento, Domingo Faustino'
              },
              {
                "type": 'life dates',
                "value": '1811-1888'
              }
            ]
          ],
          "type": 'person',
          "status": 'primary'
        },
        {
          "name": [
            "structuredValue": [
              {
                "value": 'Rojas, Ricardo'
              },
              {
                "type": 'life dates',
                "value": '1882-1957'
              }
            ]
          ],
          "type": 'person'
        }
      ]
    end
  end

  # 10. Multiple names, no primary
  context 'with multiple names, no primary' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Gaiman, Neil</namePart>
          <role>
            <roleTerm type="text">author</roleTerm>
          </role>
        </name>
        <name type="personal">
          <namePart>Pratchett, Terry</namePart>
          <role>
            <roleTerm type="text">author</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Gaiman, Neil'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'author'
            }
          ]
        },
        {
          "name": [
            {
              "value": 'Pratchett, Terry'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'author'
            }
          ]
        }
      ]
    end
  end

  context 'with multiple names, no primary, no roles' do
    let(:xml) do
      <<~XML
        <name type="corporate">
          <namePart>Hawaii International Services Agency</namePart>
        </name>
        <name type="corporate">
          <namePart>United States</namePart>
          <namePart>Office of Foreign Investment in the United States.</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Hawaii International Services Agency'
            }
          ],
          "type": 'organization'
        },
        {
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'United States'
                },
                {
                  "value": 'Office of Foreign Investment in the United States.'
                }
              ]
            }
          ],
          "type": 'organization'
        }

      ]
    end
  end

  # 11. Single name, no primary (pseudonym)
  context 'with single name, no primary (pseudonym)' do
    xit 'TODO: 6. Single name, no primary (pseudonym) - mods_to_cocina_name.txt#L473'
  end

  # 12. Multiple names with transliteration (name as value)
  # FIXME: discrepancy - missing "status": "primary" for Булгаков
  context 'with multiple names with transliteration (name as value)' do
    let(:xml) do
      <<~XML
        <name usage="primary" type="personal" script="Cyrl" altRepGroup="0">
          <namePart>Булгаков, Михаил Афанасьевич</namePart>
        </name>
        <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
          <namePart>Bulgakov, Mikhail Afanasʹevich</namePart>
        </name>
        <name type="personal" script="Cyrl" altRepGroup="1">
          <namePart>Олеша, Юрий Карлович</namePart>
        </name>
        <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
          <namePart>Olesha, I︠U︡riĭ Karlovich</namePart>
        <name>
      XML
    end

    it 'builds the cocina data structure' do
      # FIXME: missing "status": "primary" for Булгаков
      expect(build).to eq [
        {
          "name": [
            {
              "parallelValue": [
                {
                  "value": 'Булгаков, Михаил Афанасьевич',
                  "valueLanguage":
                    {
                      "valueScript": {
                        "code": 'Cyrl',
                        "source": {
                          "code": 'iso15924'
                        }
                      }
                    },
                  "status": 'primary'
                },
                {
                  "value": 'Bulgakov, Mikhail Afanasʹevich',
                  "valueLanguage":
                    {
                      "valueScript": {
                        "code": 'Latn',
                        "source": {
                          "code": 'iso15924'
                        }
                      }
                    },
                  "type": 'transliteration',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  }
                }
              ],
              "type": 'person'
            }
          ]
        },
        {
          "name": [
            {
              "parallelValue": [
                {
                  "value": 'Олеша, Юрий Карлович',
                  "valueLanguage":
                    {
                      "valueScript": {
                        "code": 'Cyrl',
                        "source": {
                          "code": 'iso15924'
                        }
                      }
                    }
                },
                {
                  "value": 'Olesha, I︠U︡riĭ Karlovich',
                  "valueLanguage":
                    {
                      "valueScript": {
                        "code": 'Latn',
                        "source": {
                          "code": 'iso15924'
                        }
                      }
                    },
                  "type": 'transliteration',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  }
                }
              ],
              "type": 'person'
            }
          ]
        }
      ]
    end
  end

  # 13. Transliterated name with parts (name as structuredValue) - reference example only
  # context 'with transliterated name with parts (name as structuredValue) - reference example only' do
  #   xit 'TODO: 13. Transliterated name with parts (name as structuredValue)) - mods_to_cocina_name.txt#L583'
  # end

  # 13b. Transliterated name with role
  context 'with transliterated name with role' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
          <namePart>&#x30EC;&#x30A2;&#x30E1;&#x30BF;&#x30EB;&#x8CC7;&#x6E90;&#x518D;&#x751F;&#x6280;&#x8853;&#x7814;&#x7A76;&#x4F1A;</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
          </role>
        </name>
        <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
          <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          name: [
            {
              parallelValue: [
                {
                  "status": 'primary',
                  "valueLanguage": {
                    "code": 'jpn',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Jpan',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  },
                  "value": 'レアメタル資源再生技術研究会'
                },
                {
                  "valueLanguage": {
                    "code": 'jpn',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Latn',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  },
                  "type": 'transliteration',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  },
                  "value": 'Rea Metaru Shigen Saisei Gijutsu Kenkyūkai'
                }
              ],

              type: 'organization'
            }
          ],
          role: [
            {
              "value": 'creator',
              "code": 'cre',
              "uri": 'http://id.loc.gov/vocabulary/relators/cre',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          ]
        }
      ]
    end
  end

  # 14. Name with et al.
  context 'with et al.' do
    xit 'TODO: 14. Name with et al. - mods_to_cocina_name.txt#L650'
  end

  # 15. Name with display label
  context 'with displayLabel' do
    xit 'TODO: 15. Name with display label - mods_to_cocina_name.txt#L673'
  end

  # 16. Name with valueURI only (authority URI)
  context 'with valueURI only' do
    xit 'TODO: 16. Name with valueURI only (authority URI) - mods_to_cocina_name.txt#L693'
  end

  # 17. Name with nameIdentifier only (RWO URI)
  context 'with nameIdentifier only (RWO URI)' do
    xit 'TODO: 17. Name with nameIdentifier only (RWO URI) - mods_to_cocina_name.txt#L713'
  end

  # 18. Full name with additional subelements
  # FIXME: works, except missing type name within the structured value
  context 'with full name with additional subelements' do
    xit 'TODO: 18. Full name with additional subelements - mods_to_cocina_name.txt#L741'
    # let(:xml) do
    #   <<~XML
    #     <name type="personal" usage="primary">
    #       <namePart>Sarmiento, Domingo Faustino</namePart>
    #       <namePart type="date">1811-1888</namePart>
    #     </name>
    #   XML
    # end
    #
    # it 'builds the cocina data structure' do
    #   expect(build).to eq [
    #     {
    #       "name": [
    #         "structuredValue": [
    #           {
    #             "value": 'Sarmiento, Domingo Faustino',
    #             "type": 'name',
    #           },
    #           {
    #             "type": 'life dates',
    #             "value": '1811-1888'
    #           }
    #         ]
    #       ],
    #       "type": 'person',
    #       "status": 'primary'
    #     }
    #   ]
    # end
  end

  # 19. Name with active date - year
  context 'with name with active date - year' do
    xit 'TODO: 19. Name with active date - year - mods_to_cocina_name.txt#L794'
    # let(:xml) do
    #   <<~XML
    #     <name type="personal">
    #       <namePart>Yao, Zongyi</namePart>
    #       <namePart type="date">Active 1618</namePart>
    #     </name>
    #   XML
    # end
    #
    # it 'builds the cocina data structure' do
    #   expect(build).to eq [
    #     {
    #       "name": [
    #         "structuredValue": [
    #           {
    #             "value": 'Yao, Zongyi',
    #             "type": 'name',
    #           },
    #           {
    #             "type": 'activity dates',
    #             "value": '1618'
    #           }
    #         ]
    #       ],
    #       "type": 'person',
    #       "status": 'primary'
    #     }
    #   ]
    # end
  end

  # 20. Name with active date - century
  context 'with name with active date - century' do
    xit 'TODO: 20. Name with active date - century - mods_to_cocina_name.txt#L794'
  end

  # 21. Name with approximate date
  context 'with name with approximate date' do
    xit 'TODO: 21. name with approximate date - mods_to_cocina_name.txt#L820'
  end

  # 22. Name with language
  context 'with name with language' do
    xit 'TODO: 22. Name with language - mods_to_cocina_name.txt#L846'
  end
end
