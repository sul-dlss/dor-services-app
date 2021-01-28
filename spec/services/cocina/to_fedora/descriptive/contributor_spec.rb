# frozen_string_literal: true

require 'rails_helper'
require 'support/mods_mapping_spec_helper'

# numbered examples refer to https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt
RSpec.describe Cocina::ToFedora::Descriptive::Contributor do
  # see spec/support/mods_mapping_spec_helper.rb for how writer is used in shared examples
  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods(mods_attributes) do
        described_class.write(xml: xml, contributors: contributors, titles: titles, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end
  let(:titles) { nil }

  context 'when contributors is nil' do
    let(:contributors) { nil }

    it_behaves_like 'cocina to MODS', '' # empty MODS
  end

  context 'when contributor model is empty' do
    # NOTE for https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L324'
    #   from_fedora builds a null structure ... so we're not going to get roleTerm back

    let(:contributors) do
      [
        Cocina::Models::Contributor.new
      ]
    end

    it_behaves_like 'cocina to MODS', '' # empty MODS
  end

  context 'with a translated name, no role' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          {
            "name": [
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
            ]
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
        <namePart>レアメタル資源再生技術研究会</namePart>
      </name>
      <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
        <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
      </name>
    XML
  end

  context 'with role' do
    context 'with empty name value and empty role value' do
      # see https://github.com/sul-dlss/dor-services-app/issues/1161
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": ''
              }
            ],
            "role": [
              {
                "value": ''
              }
            ]
          )
        ]
      end

      it_behaves_like 'cocina to MODS', <<~XML
        <name>
          <namePart/>
          <role/>
        </name>
      XML
    end

    context 'with empty name value and missing role' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": ''
              }
            ],
            "role": [
              {
                "source":
                  {
                    "code": 'marcreleator'
                  }
              }
            ]
          )
        ]
      end

      it_behaves_like 'cocina to MODS', <<~XML
        <name>
          <namePart/>
          <role/>
        </name>
      XML
    end
  end

  context 'with authority code only' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
              source: {
                code: 'naf'
              }
            }
          ],
          status: 'primary',
          type: 'person'
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <name type="personal" usage="primary" authority="naf">
        <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
      </name>
    XML
  end

  context 'with multiple names, no primary, no roles' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Hawaii International Services Agency'
            }
          ],
          "type": 'organization'
        ),
        Cocina::Models::Contributor.new(
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
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <name type="corporate">
        <namePart>Hawaii International Services Agency</namePart>
      </name>
      <name type="corporate">
        <namePart>United States</namePart>
        <namePart>Office of Foreign Investment in the United States.</namePart>
      </name>
    XML
  end

  # almost mods_to_cocina_titleInfo.txt example 6. Uniform title with authority
  # FIXME: discrepancies (see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L203)
  context 'with a personal name part of name title group' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Peele, Gregory'
            }
          ],
          "type": 'person'
        ),
        Cocina::Models::Contributor.new(
          {
            "name": [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "status": 'primary',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              }
            ]
          }
        )
      ]
    end

    let(:titles) do
      [
        Cocina::Models::Title.new(
          "structuredValue": [
            {
              "value": 'Shakespeare, William, 1564-1616',
              "type": 'name',
              "uri": 'http://id.loc.gov/authorities/names/n78095332',
              "source": {
                "uri": 'http://id.loc.gov/authorities/names/',
                "code": 'naf'
              }
            },
            {
              "value": 'Hamlet',
              "type": 'title'
            }
          ],
          "type": 'uniform',
          "uri": 'http://id.loc.gov/authorities/names/n80008522',
          "source": {
            "uri": 'http://id.loc.gov/authorities/names/',
            "code": 'naf'
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <name type="personal">
        <namePart>Peele, Gregory</namePart>
      </name>
    XML
  end

  # 13b. Transliterated name with role - needs fix to status primary
  context 'with a transliterated name with role' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
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
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
        <namePart>レアメタル資源再生技術研究会</namePart>
        <role>
          <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
          <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
        </role>
      </name>
      <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
        <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
        <role>
          <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
          <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
        </role>
      </name>
    XML
  end
end
