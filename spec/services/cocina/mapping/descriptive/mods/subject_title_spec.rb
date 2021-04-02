# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'Subject with only titleInfo subelement' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79018834">
              <title>Beowulf</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Beowulf',
              type: 'title',
              uri: 'http://id.loc.gov/authorities/names/n79018834',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Subject with only titleInfo subelement, multipart title' do
    # Example from gp286dy1254
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo>
              <title>Bible. English 1975</title>
              <partName>Jonah. English 1975</partName>
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
                  value: 'Bible. English 1975',
                  type: 'main title'
                },
                {
                  value: 'Jonah. English 1975',
                  type: 'part name'
                }
              ],
              type: 'title',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'With language attributes on subject element' do
    # adapted from xr748qv0599
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject lang="chi" script="Latn" authority="lcsh">
            <titleInfo>
              <title>Xin guo min yun dong</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              source: {
                code: 'lcsh'
              },
              valueLanguage: {
                code: 'chi',
                source: {
                  code: 'iso639-2b'
                },
                valueScript: {
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              },
              value: 'Xin guo min yun dong',
              type: 'title'
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title' do
    # Adapted from mx928ks3963.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n88244749">
              <title>Microsoft PowerPoint (Computer file)</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              groupedValue: [
                {
                  value: 'Microsoft PowerPoint (Computer file)',
                  type: 'uniform',
                  uri: 'http://id.loc.gov/authorities/names/n88244749',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'title',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'altRepGroup for alternative title (880-246)' do
    it_behaves_like 'MODS cocina mapping' do
      # based on druid:cp165bv2167

      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
             <title>Chinese pen</title>
          </titleInfo>
          <titleInfo type="alternative">
             <title>Chinese pen (Taiwan) &lt;1994-&gt;</title>
          </titleInfo>
          <titleInfo type="translated">
             <title>Contemporary Chinese literature from Taiwan, &lt;2005-&gt;</title>
          </titleInfo>
          <titleInfo type="translated" altRepGroup="1">
             <title>Dang dai Taiwan wen xue xuan yi &lt;2002-&gt;</title>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="1">
             <title>當代台灣文學選譯 &lt;2002-&gt;</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              value: 'Chinese pen',
              status: 'primary'
            },
            {
              value: 'Chinese pen (Taiwan) <1994->',
              type: 'alternative'
            },
            {
              value: 'Contemporary Chinese literature from Taiwan, <2005->',
              type: 'translated'
            },
            {
              parallelValue: [
                {
                  value: 'Dang dai Taiwan wen xue xuan yi <2002->',
                  type: 'translated'
                },
                {
                  value: '當代台灣文學選譯 <2002->',
                  type: 'alternative'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'altRepGroup for primary and alternative titles (880 for 245 and 246)' do
    xit 'not implemented' do
      let(:catkey) { '13584265' }

      let(:mods) do
        <<~XML
          <titleInfo usage="primary" altRepGroup="02">
             <title>Alkhimii͡a deneg</title>
             <subTitle>kak banki delai͡ut denʹgi... iz vozdukha</subTitle>
          </titleInfo>
          <titleInfo altRepGroup="02">
             <title>Алхимия денег</title>
             <subTitle>как банки делают деньги... из воздуха</subTitle>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="03">
             <title>Kak banki delai͡ut denʹgi... iz vozdukha</title>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="03">
             <title>Как банки делают деньги... из воздуха</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Alkhimii͡a deneg',
                      type: 'main title'
                    },
                    {
                      value: 'kak banki delai͡ut denʹgi... iz vozdukha',
                      type: 'subtitle'
                    }
                  ],
                  status: 'primary'
                },
                {
                  structuredValue: [
                    {
                      value: 'Алхимия денег',
                      type: 'main title'
                    },
                    {
                      value: 'как банки делают деньги... из воздуха',
                      type: 'subtitle'
                    }
                  ]
                }
              ]
            },
            {
              parallelValue: [
                {
                  value: 'Kak banki delai͡ut denʹgi... iz vozdukha'
                },
                {
                  value: 'Как банки делают деньги... из воздуха'
                }
              ],
              type: 'alternative'
            }
          ]
        }
      end
    end
  end

  describe 'parallel title with transliteration in primary title (245)' do
    xit 'not implemented' do
      let(:catkey) { '13681637' }

      let(:mods) do
        <<~XML
          <titleInfo usage="primary" altRepGroup="01">
             <title>Academia</title>
             <subTitle>terra historiae : studiï na poshanu Valerii͡a Smolii͡a = Academia : terra historiae : studies in honor of Valerii Smolii</subTitle>
          </titleInfo>
          <titleInfo altRepGroup="01">
             <title>Academia</title>
             <subTitle>terra historiae : студії на пошану Валерія Смолія = Academia : terra historiae : studies in honor of Valerii Smolii</subTitle>
          </titleInfo>
          <titleInfo type="translated">
             <title>Academia</title>
             <subTitle>terra historiae : studies in honor of Valerii Smolii</subTitle>
          </titleInfo>
          <titleInfo type="alternative">
             <title>Academia terra historiae</title>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Academia',
                      type: 'main title'
                    },
                    {
                      value: 'terra historiae : studiï na poshanu Valerii͡a Smolii͡a = Academia : terra historiae : studies in honor of Valerii Smolii',
                      type: 'subtitle'
                    }
                  ],
                  status: 'primary'
                },
                {
                  structuredValue: [
                    {
                      value: 'Academia',
                      type: 'main title'
                    },
                    {
                      value: 'terra historiae : студії на пошану Валерія Смолія = Academia : terra historiae : studies in honor of Valerii Smolii',
                      type: 'subtitle'
                    }
                  ]
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Academia',
                  type: 'main title'
                },
                {
                  value: 'terra historiae : studies in honor of Valerii Smolii',
                  type: 'subtitle'
                }
              ],
              type: 'translated'
            },
            {
              value: 'Academia terra historiae',
              type: 'alternative'
            }
          ]
        }
      end
    end
  end

  describe 'parallel title in Latin and non-Latin scripts, non-Latin script transliterated in primary title (245)' do
    xit 'not implemented' do
      let(:catkey) { '486104' }

      let(:mods) do
        <<~XML
          <titleInfo usage="primary">
            <title>Bibliografija Jugoslavije</title>
            <subTitle>Bibliografii͡a I͡Ugoslavii. Knigi, broshi͡ury i noty = Bibliography of Yugoslavia. Books, pamphlets, and music</subTitle>
            <partName>Knjige, brošure i muzikalije =</partName>
          </titleInfo>
          <titleInfo type="abbreviated">
            <title>Bibliogr Jugosl Knjige</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Knjige, brošure i muzikalije</title>
            </titleInfo>
          <titleInfo type="translated" altRepGroup="01">
            <title>Bibliografii͡a I͡Ugoslavii</title>
            <partName>Knigi, broshi͡ury i noty</partName>
          </titleInfo>
          <titleInfo type="translated">
            <title>Bibliography of Yugoslavia</title>
            <partName>Books, pamphlets, and music</partName>
          </titleInfo>
          <titleInfo type="alternative" altRepGroup="01">
            <title>Библиография Югославии</title>
            <partName>Книги, брошюры и ноты</partName>
          </titleInfo>
        XML
      end

      let(:cocina) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Bibliografija Jugoslavije',
                  type: 'main title'
                },
                {
                  value: 'Bibliografii͡a I͡Ugoslavii. Knigi, broshi͡ury i noty = Bibliography of Yugoslavia. Books, pamphlets, and music',
                  type: 'subtitle'
                },
                {
                  value: 'Knjige, brošure i muzikalije =',
                  type: 'part name'
                }
              ],
              status: 'primary'
            },
            {
              value: 'Bibliogr Jugosl Knjige',
              type: 'abbreviated'
            },
            {
              value: 'Knjige, brošure i muzikalije',
              type: 'alternative'
            },
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Bibliografii͡a I͡Ugoslavii',
                      type: 'main title'
                    },
                    {
                      value: 'Knigi, broshi͡ury i noty',
                      type: 'subtitle'
                    }
                  ],
                  type: 'translated'
                },
                {
                  structuredValue: [
                    {
                      value: 'Библиография Югославии',
                      type: 'main title'
                    },
                    {
                      value: 'Книги, брошюры и ноты',
                      type: 'subtitle'
                    }
                  ],
                  type: 'alternative'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Bibliography of Yugoslavia',
                  type: 'main title'
                },
                {
                  value: 'Books, pamphlets, and music',
                  type: 'part name'
                }
              ]
            }
          ]
        }
      end
    end
  end
end
