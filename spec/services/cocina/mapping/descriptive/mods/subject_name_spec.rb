# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject name <--> cocina mappings' do
  describe 'Name subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Dunnett, Dorothy',
              type: 'person'
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with multiple namePart elements - example 1' do
    # For mapping purposes, the name type is "name" if a more specific name type cannot be discerned.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal">
              <namePart>Nakahama, Manjir&#x14D;</namePart>
              <namePart type="date">1827-1898</namePart>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Nakahama, Manjirō',
                  type: 'name'
                },
                {
                  value: '1827-1898',
                  type: 'life dates'
                }
              ],
              type: 'person',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with multiple namePart elements - example 2' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal">
              <namePart>Saki</namePart>
              <namePart type="date">1870-1916</namePart>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Saki',
                  type: 'name'
                },
                {
                  value: '1870-1916',
                  type: 'life dates'
                }
              ],
              type: 'person',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/n79046044">
              <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
              type: 'person',
              uri: 'http://id.loc.gov/authorities/names/n79046044',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with additional terms' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'person'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with additional terms, authority for set' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic>Homes and haunts</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'person'
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic'
                }
              ],
              uri: 'http://id.loc.gov/authorities/subjects/sh85120951',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with additional terms, authority for terms' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'person',
                  uri: 'http://id.loc.gov/authorities/names/n78095332',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh99005711',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with additional terms, authority for terms and set' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh85120951">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/n78095332">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh99005711">Homes and haunts</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Shakespeare, William, 1564-1616',
                  type: 'person',
                  uri: 'http://id.loc.gov/authorities/names/n78095332',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                },
                {
                  value: 'Homes and haunts',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh99005711',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                }
              ],
              uri: 'http://id.loc.gov/authorities/subjects/sh85120951',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name-title subject with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n97075542">
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Dunnett, Dorothy',
                  type: 'person'
                },
                {
                  value: 'Lymond chronicles',
                  type: 'title'
                }
              ],
              uri: 'http://id.loc.gov/authorities/names/n97075542',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name-title subject with authority plus authority for name' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n97075542">
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
              valueURI="http://id.loc.gov/authorities/names/n50025011" type="personal">
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <titleInfo>
              <title>Lymond chronicles</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Dunnett, Dorothy',
                  type: 'person',
                  uri: 'http://id.loc.gov/authorities/names/n50025011',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                },
                {
                  value: 'Lymond chronicles',
                  type: 'title'
                }
              ],
              uri: 'http://id.loc.gov/authorities/names/n97075542',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Name-title subject with additional terms including genre subdivision, authority for set' do
    # Authority is not applied to form because the term may be a subject subdivision, with a different term for being used alone.
    let(:mods) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
          valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
          <name type="personal">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo>
            <title>Hamlet</title>
          </titleInfo>
          <genre>Bibliographies</genre>
        </subject>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
          valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
          <name type="personal">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo>
            <title>Hamlet</title>
          </titleInfo>
          <genre>Bibliographies</genre>
        </subject>
        <genre>Bibliographies</genre>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            structuredValue: [
              {
                value: 'Shakespeare, William, 1564-1616',
                type: 'person'
              },
              {
                value: 'Hamlet',
                type: 'title'
              },
              {
                value: 'Bibliographies',
                type: 'genre'
              }
            ],
            uri: 'http://id.loc.gov/authorities/subjects/sh85120809',
            source: {
              code: 'lcsh',
              uri: 'http://id.loc.gov/authorities/subjects/'
            }
          }
        ],
        form: [
          {
            value: 'Bibliographies',
            type: 'genre'
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Name-title subject with additional terms including genre subdivision, authority for terms' do
    let(:mods) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
            valueURI="http://id.loc.gov/authorities/names/n80008522">
            <title>Hamlet</title>
          </titleInfo>
          <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh99001362">Bibliographies</genre>
        </subject>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <subject authority="lcsh">
          <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names"
            valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <titleInfo authority="naf" authorityURI="http://id.loc.gov/authorities/names"
            valueURI="http://id.loc.gov/authorities/names/n80008522">
            <title>Hamlet</title>
          </titleInfo>
          <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects"
            valueURI="http://id.loc.gov/authorities/subjects/sh99001362">Bibliographies</genre>
        </subject>
        <genre>Bibliographies</genre>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            structuredValue: [
              {
                value: 'Shakespeare, William, 1564-1616',
                type: 'person',
                uri: 'http://id.loc.gov/authorities/names/n78095332',
                source: {
                  code: 'naf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                value: 'Hamlet',
                type: 'title',
                uri: 'http://id.loc.gov/authorities/names/n80008522',
                source: {
                  code: 'naf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              },
              {
                value: 'Bibliographies',
                type: 'genre',
                uri: 'http://id.loc.gov/authorities/subjects/sh99001362',
                source: {
                  code: 'lcsh',
                  uri: 'http://id.loc.gov/authorities/subjects/'
                }
              }
            ]
          }
        ],
        form: [
          {
            value: 'Bibliographies',
            type: 'genre'
          }
        ]
      }
    end

    xit 'not implemented'
  end

  describe 'Name subject with parts and genre subdivision' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal">
              <namePart>Debord, Guy</namePart>
              <namePart type="date">1931-1994</namePart>
            </name>
            <topic>Criticism and interpretation</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  structuredValue: [
                    {
                      value: 'Debord, Guy',
                      type: 'name'
                    },
                    {
                      value: '1931-1994',
                      type: 'life dates'
                    }
                  ],
                  type: 'person'
                },
                {
                  value: 'Criticism and interpretation',
                  type: 'topic'
                }
              ],
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <name xlink:href="http://name.org/name" />
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'name',
              valueAt: 'http://name.org/name'
            }
          ]
        }
      end
    end
  end

  describe 'Name subject with role' do
    # Adapted from bb945fn7289
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n84234111">
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/dpc">depicted</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/dpc">dpc</roleTerm>
              </role>
              <namePart>Hugh Capet, King of France, approximately 938-996</namePart>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Hugh Capet, King of France, approximately 938-996',
              type: 'person',
              uri: 'http://id.loc.gov/authorities/names/n84234111',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              },
              note: [
                {
                  type: 'role',
                  value: 'depicted',
                  code: 'dpc',
                  uri: 'http://id.loc.gov/vocabulary/relators/dpc',
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
    end
  end

  describe 'Name subject with display form and role' do
    # Adapted from druid:vx363td7520

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <name type="personal">
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                  valueURI="http://id.loc.gov/vocabulary/relators/dpc">depicted</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/"
                  valueURI="http://id.loc.gov/vocabulary/relators/dpc">dpc</roleTerm>
              </role>
              <namePart type="family">Nole</namePart>
              <namePart type="given">Andneas Colijns de</namePart>
              <namePart type="date">1590-?</namePart>
              <displayForm>Nole, Andneas Colijns de, 1590-?</displayForm>
            </name>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'person',
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Nole',
                      type: 'surname'
                    },
                    {
                      value: 'Andneas Colijns de',
                      type: 'forename'
                    },
                    {
                      value: '1590-?',
                      type: 'life dates'
                    }
                  ]
                },
                {
                  value: 'Nole, Andneas Colijns de, 1590-?',
                  type: 'display'
                }
              ],
              note: [
                {
                  type: 'role',
                  value: 'depicted',
                  code: 'dpc',
                  uri: 'http://id.loc.gov/vocabulary/relators/dpc',
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
    end
  end

  # Data consistency fix
  describe 'Single subject subelement with authority code same as subject, no URI' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <subject authority="local">
          <name type="personal" authority="local">
            <namePart>Reinhold, John</namePart>
          </name>
        </subject>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            value: 'Reinhold, John',
            type: 'person',
            source: {
              code: 'local'
            }
          }
        ]
      }
    end

    let(:roundtrip_mods) do
      <<~XML
        <subject authority="local">
          <name type="personal">
            <namePart>Reinhold, John</namePart>
          </name>
        </subject>
      XML
    end
  end
end
