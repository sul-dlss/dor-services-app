# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS physicalDescription <--> cocina mappings' do
  describe 'Single physical description with all subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <reformattingQuality>access</reformattingQuality>
            <internetMediaType>image/jpeg</internetMediaType>
            <extent>1 sheet</extent>
            <digitalOrigin>reformatted digital</digitalOrigin>
            <note displayLabel="Condition">Small tear at top right corner.</note>
            <note displayLabel="Material" type="material">Paper</note>
            <note displayLabel="Layout" type="layout">34 and 24 lines to a page</note>
            <note displayLabel="Height (mm)" type="dimensions">210</note>
            <note displayLabel="Width (mm)" type="dimensions">146</note>
            <note displayLabel="Collation" type="collation">1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).</note>
            <note displayLabel="Writing" type="handNote">change of hand</note>
            <note displayLabel="Foliation" type="foliation">ff. i + 1-51 + ii-iii</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'ink on paper',
              type: 'form'
            },
            {
              value: 'access',
              type: 'reformatting quality',
              source: {
                value: 'MODS reformatting quality terms'
              }
            },
            {
              value: 'image/jpeg',
              type: 'media type',
              source: {
                value: 'IANA media types'
              }
            },
            {
              value: '1 sheet',
              type: 'extent'
            },
            {
              value: 'reformatted digital',
              type: 'digital origin',
              source: {
                value: 'MODS digital origin terms'
              }
            },
            {
              note: [
                {
                  value: 'Small tear at top right corner.',
                  displayLabel: 'Condition'
                },
                {
                  value: 'Paper',
                  displayLabel: 'Material',
                  type: 'material'
                },
                {
                  value: '34 and 24 lines to a page',
                  displayLabel: 'Layout',
                  type: 'layout'
                },
                {
                  value: '210',
                  displayLabel: 'Height (mm)',
                  type: 'dimensions'
                },
                {
                  value: '146',
                  displayLabel: 'Width (mm)',
                  type: 'dimensions'
                },
                {
                  value: '1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).',
                  displayLabel: 'Collation',
                  type: 'collation'
                },
                {
                  value: 'change of hand',
                  displayLabel: 'Writing',
                  type: 'handNote'
                },
                {
                  value: 'ff. i + 1-51 + ii-iii',
                  displayLabel: 'Foliation',
                  type: 'foliation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple physical descriptions' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>audio recording</form>
            <extent>1 audiocassette</extent>
          </physicalDescription>
          <physicalDescription>
            <form>transcript</form>
            <extent>5 pages</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              groupedValue: [
                {
                  value: 'audio recording',
                  type: 'form'
                },
                {
                  value: '1 audiocassette',
                  type: 'extent'
                }
              ]
            },
            {
              groupedValue: [
                {
                  value: 'transcript',
                  type: 'form'
                },
                {
                  value: '5 pages',
                  type: 'extent'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual physical descriptions' do
    # based on druid:bx458nk9866
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription altRepGroup="1">
            <form authority="gmd">cartographic material</form>
          </physicalDescription>
          <physicalDescription altRepGroup="1">
            <form authority="gmd">地図資料</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              parallelValue: [
                {
                  value: 'cartographic material'
                },
                {
                  value: '地図資料'
                }
              ],
              type: 'form',
              source: {
                code: 'gmd'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual physical descriptions with multiple subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription altRepGroup="1">
            <form authority="gmd">cartographic material</form>
            <extent>1 page</extent>
          </physicalDescription>
          <physicalDescription altRepGroup="1">
            <form authority="gmd">地図資料</form>
            <extent>1 地</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              parallelValue: [
                {
                  groupedValue: [
                    {
                      value: 'cartographic material',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 page',
                      type: 'extent'
                    }
                  ]
                },
                {
                  groupedValue: [
                    {
                      value: '地図資料',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 地',
                      type: 'extent'
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

  describe 'Multilingual physical descriptions with same displayLabel' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription altRepGroup="1" displayLabel="Description">
            <form authority="gmd">cartographic material</form>
            <extent>1 page</extent>
          </physicalDescription>
          <physicalDescription altRepGroup="1" displayLabel="Description">
            <form authority="gmd">地図資料</form>
            <extent>1 地</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              parallelValue: [
                {
                  groupedValue: [
                    {
                      value: 'cartographic material',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 page',
                      type: 'extent'
                    }
                  ]
                },
                {
                  groupedValue: [
                    {
                      value: '地図資料',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 地',
                      type: 'extent'
                    }
                  ]
                }
              ],
              displayLabel: 'Description'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual physical descriptions with different displayLabel' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription altRepGroup="1" displayLabel="Description">
            <form authority="gmd">cartographic material</form>
            <extent>1 page</extent>
          </physicalDescription>
          <physicalDescription altRepGroup="1" displayLabel="図">
            <form authority="gmd">地図資料</form>
            <extent>1 地</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              parallelValue: [
                {
                  groupedValue: [
                    {
                      value: 'cartographic material',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 page',
                      type: 'extent'
                    }
                  ],
                  displayLabel: 'Description'
                },
                {
                  groupedValue: [
                    {
                      value: '地図資料',
                      type: 'form',
                      source: {
                        code: 'gmd'
                      }
                    },
                    {
                      value: '1 地',
                      type: 'extent'
                    }
                  ],
                  displayLabel: '図'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Form with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form authority="aat" authorityURI="http://vocab.getty.edu/aat/"
              valueURI="http://vocab.getty.edu/aat/300041356">mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'mezzotints (prints)',
              type: 'form',
              uri: 'http://vocab.getty.edu/aat/300041356',
              source: {
                code: 'aat',
                uri: 'http://vocab.getty.edu/aat/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Display label with single form' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>metal embossed on wood</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'metal embossed on wood',
              type: 'form',
              displayLabel: 'Medium'
            }
          ]
        }
      end
    end
  end

  describe 'Display label with multiple form' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>metal embossed on wood</form>
            <form>mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              groupedValue: [
                {
                  value: 'metal embossed on wood',
                  type: 'form'
                },
                {
                  value: 'mezzotints (prints)',
                  type: 'form'
                }
              ],
              displayLabel: 'Medium'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple physicalDescription with different display labels' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>ink</form>
          </physicalDescription>
          <physicalDescription displayLabel="Mount">
            <form>silk</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        # Forms must go in separate physicalDescription elements to allow
        # preserving both displayLabels.
        {
          form: [
            {
              value: 'ink',
              type: 'form',
              displayLabel: 'Medium'
            },
            {
              value: 'silk',
              type: 'form',
              displayLabel: 'Mount'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple form, some with displayLabel and some without' do
    xit 'updated spec' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>metal embossed on wood</form>
          </physicalDescription>
          <physicalDescription>
            <form>mezzotints (prints)</form>
            <note>color</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        # Subelements with no displayLabel go in same physicalDescription
        {
          form: [
            {
              value: 'metal embossed on wood',
              type: 'form',
              displayLabel: 'Medium'
            },
            {
              groupedValue: [
                {
                  value: 'mezzotints (prints)',
                  type: 'form'
                },
                {
                  note: [
                    {
                      value: 'color'
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

  describe 'Extent with unit' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <extent unit="linear foot (3 folders and 8 audiocassettes)">.5</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: '.5',
              type: 'extent',
              note: [
                {
                  value: 'linear foot (3 folders and 8 audiocassettes)',
                  type: 'unit'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Extent with unit with sibling' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form authority="marcform">print</form>
            <extent unit="linear foot (3 folders and 8 audiocassettes)">.5</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'print',
              type: 'form',
              source: {
                code: 'marcform'
              }
            },
            {
              value: '.5',
              type: 'extent',
              note: [
                {
                  value: 'linear foot (3 folders and 8 audiocassettes)',
                  type: 'unit'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Extent with unit and note sibling' do
    # druid:gx952gd8699
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <extent unit="linear feet (16 boxes)">27.25</extent>
            <note type="arrangement">The records are arranged in four series: Series 1. Administrative Records; Series 2. Photographs; Series 3. Emeriti files; Series 4. Posters.</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: '27.25',
              type: 'extent',
              note: [
                {
                  value: 'linear feet (16 boxes)',
                  type: 'unit'
                }
              ]
            },
            {
              note: [
                {
                  value: 'The records are arranged in four series: Series 1. Administrative Records; Series 2. Photographs; Series 3. Emeriti files; Series 4. Posters.',
                  type: 'arrangement'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple extent with one sibling note' do
    it_behaves_like 'MODS cocina mapping' do
      # druid:bh920np8004
      let(:mods) do
        <<~XML
          <physicalDescription>
            <extent unit="Linear feet">4</extent>
            <extent unit="boxes">5</extent>
            <note type="arrangement">Arranged in the following 4 series: 1. Biographical Materials ; 2. Education and Research ; 3. Patents ; 4. Oversized Materials</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: '4',
              type: 'extent',
              note: [
                {
                  value: 'Linear feet',
                  type: 'unit'
                }
              ]
            },
            {
              value: '5',
              type: 'extent',
              note: [
                {
                  value: 'boxes',
                  type: 'unit'
                }
              ]
            },
            {
              note: [
                {
                  value: 'Arranged in the following 4 series: 1. Biographical Materials ; 2. Education and Research ; 3. Patents ; 4. Oversized Materials',
                  type: 'arrangement'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Physical description with empty note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <note displayLabel="Condition" />
          </physicalDescription>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'ink on paper',
              type: 'form'
            }
          ]
        }
      end
    end
  end
end
