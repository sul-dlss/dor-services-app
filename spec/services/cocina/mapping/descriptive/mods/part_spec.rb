# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS part <--> cocina mappings' do
  describe 'Top level part' do
    # Adapted from dx023mr7150
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <part>
            <detail>
              <caption>Late Summer 1997</caption>
            </detail>
          </part>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              groupedValue: [
                {
                  value: 'Late Summer 1997',
                  type: 'caption'
                }
              ],
              type: 'part'
            }
          ]
        }
      end
    end
  end

  describe 'isReferencedBy relatedItem/part (510c)' do
    # Adapted from kf840zn4567
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Alden, J.E. European Americana,</title>
            </titleInfo>
            <note>Not recorded at Monterey Jazz Festival</note>
            <part>
              <detail type="part">
                <number>635/94</number>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Alden, J.E. European Americana</title>
            </titleInfo>
            <note>Not recorded at Monterey Jazz Festival</note>
            <part>
              <detail type="part">
                <number>635/94</number>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      # Strip trailing comma or period from title.

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'referenced by',
              title: [
                {
                  value: 'Alden, J.E. European Americana'
                }
              ],
              note: [
                {
                  value: 'Not recorded at Monterey Jazz Festival'
                },
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: 'part',
                      type: 'detail type'
                    },
                    {
                      value: '635/94',
                      type: 'number'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'constituent relatedItem/part' do
    # Adapted from vt758zn6912
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo>
              <title>[Unidentified sextet]</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>02:T00:04:01</number>
                <caption>Marker</caption>
                <title>Side A</title>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Steal Away</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>03:T00:08:35</number>
                <caption>Marker</caption>
                <title>Side B</title>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Railroad Porter Blues</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>04:T00:15:35</number>
                <caption>Marker</caption>
                <title>Side A</title>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'has part',
              title: [
                {
                  value: '[Unidentified sextet]'
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: 'marker',
                      type: 'detail type'
                    },
                    {
                      value: '02:T00:04:01',
                      type: 'number'
                    },
                    {
                      value: 'Marker',
                      type: 'caption'
                    },
                    {
                      value: 'Side A',
                      type: 'title'
                    }
                  ]
                }
              ]
            },
            {
              type: 'has part',
              title: [
                {
                  value: 'Steal Away'
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: 'marker',
                      type: 'detail type'
                    },
                    {
                      value: '03:T00:08:35',
                      type: 'number'
                    },
                    {
                      value: 'Marker',
                      type: 'caption'
                    },
                    {
                      value: 'Side B',
                      type: 'title'
                    }
                  ]
                }
              ]
            },
            {
              type: 'has part',
              title: [
                {
                  value: 'Railroad Porter Blues'
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: 'marker',
                      type: 'detail type'
                    },
                    {
                      value: '04:T00:15:35',
                      type: 'number'
                    },
                    {
                      value: 'Marker',
                      type: 'caption'
                    },
                    {
                      value: 'Side A',
                      type: 'title'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'host relatedItem/part with text subelement' do
    it_behaves_like 'MODS cocina mapping' do
      # Adapted from dx917cq2361

      let(:mods) do
        <<~XML
          <relatedItem type="host">
            <titleInfo>
              <title>[Recueil. Collection Smith-Lesouëf. Estampes révolutionnaires]</title>
            </titleInfo>
            <identifier type="local">(FrPBN)42417922</identifier>
            <part>
              <text>10</text>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'part of',
              title: [
                {
                  value: '[Recueil. Collection Smith-Lesouëf. Estampes révolutionnaires]'
                }
              ],
              identifier: [
                {
                  value: '(FrPBN)42417922',
                  type: 'local',
                  source: {
                    code: 'local'
                  }
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: '10',
                      type: 'text'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'host/relatedItem with part/date subelement' do
    it_behaves_like 'MODS cocina mapping' do
      # Adapted from ht052ks5388

      let(:mods) do
        <<~XML
          <relatedItem type="host" displayLabel="Published in">
            <titleInfo>
              <title>The Business Week Top 1000</title>
            </titleInfo>
            <part>
              <date>1999</date>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'part of',
              displayLabel: 'Published in',
              title: [
                {
                  value: 'The Business Week Top 1000'
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: '1999',
                      type: 'date'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Part with list' do
    # Adapted from bj635gv2695
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="host" displayLabel="Appears in">
            <titleInfo>
              <title>A general atlas, describing the whole universe</title>
            </titleInfo>
            <identifier type="local" displayLabel="Pub list no.">0411.000</identifier>
            <part>
              <extent unit="page">
                <list>10</list>
              </extent>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'part of',
              displayLabel: 'Appears in',
              title: [
                {
                  value: 'A general atlas, describing the whole universe'
                }
              ],
              identifier: [
                {
                  type: 'local',
                  displayLabel: 'Pub list no.',
                  value: '0411.000',
                  source: {
                    code: 'local'
                  }
                }
              ],
              note: [
                {
                  type: 'part',
                  groupedValue: [
                    {
                      value: 'page',
                      type: 'extent unit'
                    },
                    {
                      value: '10',
                      type: 'list'
                    }
                  ]
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Part with hierarchy' do
    # Adapted from mw409jk5241
    # Hierarchy indicated by multiple <detail> with type attribute.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="host" displayLabel="Published in">
            <titleInfo>
              <title>Journal of Information Science</title>
            </titleInfo>
            <part>
              <detail type="volume">
                <caption>Vol.</caption>
                <number>1</number>
              </detail>
              <detail type="issue">
                <caption>No.</caption>
                <number>4</number>
              </detail>
              <extent unit="page">
                <start>223</start>
                <end>226</end>
              </extent>
              <date>1979-08</date>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'part of',
              displayLabel: 'Published in',
              title: [
                {
                  value: 'Journal of Information Science'
                }
              ],
              note: [
                {
                  structuredValue: [
                    {
                      groupedValue: [
                        {
                          value: 'volume',
                          type: 'detail type'
                        },
                        {
                          value: 'Vol.',
                          type: 'caption'
                        },
                        {
                          value: '1',
                          type: 'number'
                        }
                      ]
                    },
                    {
                      groupedValue: [
                        {
                          value: 'issue',
                          type: 'detail type'
                        },
                        {
                          value: 'No.',
                          type: 'caption'
                        },
                        {
                          value: '4',
                          type: 'number'
                        }
                      ]
                    },
                    {
                      groupedValue: [
                        {
                          value: 'page',
                          type: 'extent unit'
                        },
                        {
                          structuredValue: [
                            {
                              value: '223',
                              type: 'start'
                            },
                            {
                              value: '226',
                              type: 'end'
                            }
                          ]
                        }
                      ]
                    },
                    {
                      value: '1979-08',
                      type: 'date'
                    }
                  ],
                  type: 'part'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Monolingual part with all subelements' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    let(:mods) do
      <<~XML
        <part type="article" order="1">
          <detail type="section">
            <number>Section 1</number>
            <caption>This is the first section.</caption>
            <title>A Section</title>
          </detail>
          <extent unit="pages">
            <start>4</start>
            <end>9</end>
            <total>6</total>
            <list>pages 4-9<list>
          </extent>
          <date encoding="w3cdtf" keyDate="true" qualifier="approximate" calendar="Gregorian" point="start">2020-11</date>
          <text type="summary" displayLabel="Abstract">Here is some more info about what this article is about.</text>
        </part>
      XML
    end
  end

  describe 'Multilingual part' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    # Every text element plus part, other than extent/total, can have the lang, script, and transliteration attributes.
    # The altRepGroup attribute appears only on the part element.
    let(:mods) do
      <<~XML
        <part type="article" order="1" altRepGroup="1" lang="eng" script="Latn">
          <detail>
            <title>This is a title in English</title>
          </detail>
        </part>
        <part type="article" altRepGroup="1" lang="rus" script="Cyrl" transliteraion = "ALA/LC Romanization Tables">
          <detail>
            <title>Pretend this is the same title in Russian</title>
          </detail>
        </part>
      XML
    end
  end

  describe 'Full hierarchical detail' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    let(:mods) do
      <<~XML
        <part>
          <detail type="volume" level="0">
            <title>Some animals</title>
          </detail>
          <detail type="chapter" level="1">
            <title>Chapter 1: Mammals</title>
          </detail>
          <detail> type="section" level="2">
            <caption>This section is about cats.</caption>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about rabbits.</caption>
          </detail>
          <detail type="chapter" level="1">
            <title>Chapter 2: Amphibians</title>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about salamanders.</caption>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about frogs.</caption>
          </detail>
        </part>
      XML
    end
  end

  describe 'Multiple ordered parts' do
    # valid MODS, but Arcadia will not map unless they show up in our data.
    xit 'not mapped (to cocina) unless they show up in our data'

    let(:mods) do
      <<~XML
        <part type="volume" order="1">
          <detail>
            <title>A-L</title>
            <number>Volume 1</number>
            <caption>It's about some stuff.</caption>
          </detail>
        </part>
        <part type="volume" order="2">
          <detail>
            <title>M-Z</title>
            <number>Volume 2</number>
            <caption>It's about some other stuff.</caption>
          </detail>
        <part>
      XML
    end
  end
end
