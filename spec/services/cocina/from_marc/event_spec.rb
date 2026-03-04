# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Event do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:require_title) { true }
    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with a publication event' do
      context 'with a single script that has a 260$abc' do
        let(:marc_hash) do
          {
            'fields' => [
              { '260' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Basingstoke :'
                  },
                  {
                    'b' => 'Macmillan,'
                  },
                  {
                    'c' => '1997.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: 'Basingstoke' }],
            contributor: [{ name: [{ value: 'Macmillan' }], role: [{ value: 'publisher' }] }],
            date: [{ value: '1997', type: 'publication' }]
          }]
        end
      end

      context 'with a single script that has no 260$c' do
        # a11545514

        let(:marc_hash) do
          {
            'fields' => [
              { '260' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => '[S.l.] :'
                  },
                  {
                    'b' => 'Open Book Publishers, '
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: '[S.l.]' }],
            contributor: [{ name: [{ value: 'Open Book Publishers' }], role: [{ value: 'publisher' }] }]
          }]
        end
      end

      context 'with a single script that has no 260 $a or $b' do
        # a10772681
        let(:marc_hash) do
          {
            'fields' => [
              { '260' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'c' => 'June 2003.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event' do
          expect(build).to eq [{
            type: 'publication',
            date: [{ value: 'June 2003', type: 'publication' }]
          }]
        end
      end

      context 'with multiple $b subfields' do
        # See a10422378
        let(:marc_hash) do
          {
            'fields' => [
              { '260' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => '[Stanford, Calif.] :'
                  },
                  {
                    'b' => 'Stanford Law School ;'
                  },
                  {
                    'a' => '[New York] :'
                  },
                  {
                    'b' => 'NYU School of Law,'
                  },
                  {
                    'c' => 'c2012.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event' do
          expect(build).to eq [{
            type: 'publication',
            location: [
              {
                value: '[Stanford, Calif.]'
              },
              {
                value: '[New York]'
              }
            ],
            contributor: [
              {
                name: [
                  {
                    value: 'Stanford Law School'
                  }
                ],
                role: [
                  {
                    value: 'publisher'
                  }
                ]
              },
              {
                name: [
                  {
                    value: 'NYU School of Law'
                  }
                ],
                role: [
                  {
                    value: 'publisher'
                  }
                ]
              }
            ],
            date: [{ value: 'c2012', type: 'publication' }]
          }]
        end
      end

      context 'with multiple scripts' do
        let(:marc_hash) do
          {
            'fields' => [
              { '260' => {
                  'ind1' => ' ',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-01'
                    },
                    {
                      'a' => 'New York ;'
                    },
                    {
                      'a' => 'Geneva :'
                    },
                    {
                      'b' => 'United Nations,'
                    },
                    {
                      'c' => '©2012.'
                    }
                  ]
                },
                '880' => {
                  'ind1' => ' ',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '260-04'
                    },
                    {
                      'a' => 'Нью-Йорк ;'
                    },
                    {
                      'a' => 'Женева :'
                    },
                    {
                      'b' => 'Организация Объединенных Наций,'
                    },
                    {
                      'c' => '2012.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns publication event' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: 'New York' }, { value: 'Geneva' }],
            contributor: [{ name: [{ value: 'United Nations' }], role: [{ value: 'publisher' }] }],
            date: [{ value: '©2012', type: 'publication' }]
          }, {
            type: 'publication',
            location: [{ value: 'Нью-Йорк' }, { value: 'Женева' }],
            contributor: [{ name: [{ value: 'Организация Объединенных Наций' }], role: [{ value: 'publisher' }] }],
            date: [{ value: '2012', type: 'publication' }]
          }]
        end
      end
    end

    context 'with publication and manufacture event (260 abcefg)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '260' => {
              'ind1' => ' ',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'London :'
                },
                {
                  'b' => 'Arts Council of Great Britain,'
                },
                {
                  'c' => '1976'
                },
                {
                  'e' => '(Twickenham :'
                },
                {
                  'f' => 'CTD Printers,'
                },
                {
                  'g' => '1974)'
                }
              ]
            } }
          ]
        }
      end

      it 'returns both publication and manufacture events' do
        expect(build).to eq [{
          type: 'publication',
          location: [{ value: 'London' }],
          contributor: [{ name: [{ value: 'Arts Council of Great Britain' }], role: [{ value: 'publisher' }] }],
          date: [{ value: '1976', type: 'publication' }]
        }, {
          type: 'manufacture',
          location: [{ value: '(Twickenham' }],
          contributor: [{ name: [{ value: 'CTD Printers' }] }],
          date: [{ value: '1974)', type: 'manufacture' }]
        }]
      end
    end

    context 'with production event (264 ind2=0)' do
      # see a10106195
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => '0',
              'subfields' => [
                {
                  'a' => 'Stanford, Calif. :'
                },
                {
                  'b' => 'Dept. of Statistics, Stanford University,'
                },
                {
                  'c' => '2001.'
                }
              ]
            } }
          ]
        }
      end

      it 'returns production event' do
        expect(build).to eq [{
          type: 'production',
          location: [
            {
              value: 'Stanford, Calif.'
            }
          ],
          contributor: [
            {
              role: [
                {
                  value: 'creator'
                }
              ],
              name: [
                {
                  value: 'Dept. of Statistics, Stanford University'
                }
              ]
            }
          ],
          date: [{ value: '2001', type: 'production' }]
        }]
      end
    end

    context 'with publication event (264 ind2=1)' do
      context 'with multiple publishers' do
        let(:marc_hash) do
          {
            'fields' => [
              { '264' => {
                'ind1' => ' ',
                'ind2' => '1',
                'subfields' => [
                  {
                    'a' => '[France] :'
                  },
                  {
                    'b' => 'Erato :'
                  },
                  {
                    'b' => 'Warner Classics,'
                  },
                  {
                    'c' => '[2017]'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event with multiple publishers' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: '[France]' }],
            contributor: [
              { name: [{ value: 'Erato' }], role: [{ value: 'publisher' }] },
              { name: [{ value: 'Warner Classics' }], role: [{ value: 'publisher' }] }
            ],
            date: [{ value: '[2017]', type: 'publication' }]
          }]
        end
      end

      context 'with multiple locations' do
        # see a10551837
        let(:marc_hash) do
          {
            'fields' => [
              { '264' => {
                'ind1' => ' ',
                'ind2' => '1',
                'subfields' => [
                  {
                    'a' => 'À Paris :'
                  },
                  {
                    'b' => 'publiée par Naderman ;'
                  },
                  {
                    'a' => 'À Londres :'
                  },
                  {
                    'b' => 'par Clementi & Co.,'
                  },
                  {
                    'c' => '[after 1803]'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event with multiple publishers' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: 'À Paris' }, { value: 'À Londres' }],
            contributor: [
              { name: [{ value: 'publiée par Naderman' }], role: [{ value: 'publisher' }] },
              { name: [{ value: 'par Clementi & Co.' }], role: [{ value: 'publisher' }] }
            ],
            date: [{ value: '[after 1803]', type: 'publication' }]
          }]
        end
      end

      context 'with no date' do
        # see a493225
        let(:marc_hash) do
          {
            'fields' => [
              { '264' => {
                'ind1' => '2',
                'ind2' => '1',
                'subfields' => [
                  {
                    '3' => '<Apr. 1988->'
                  },
                  {
                    'a' => 'Emeryville, Calif. : '
                  },
                  {
                    'b' => 'Mix Publications, Inc.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event with multiple publishers' do
          expect(build).to eq [{
            type: 'publication',
            location: [{ value: 'Emeryville, Calif.' }],
            contributor: [
              { name: [{ value: 'Mix Publications, Inc.' }], role: [{ value: 'publisher' }] }
            ]
          }]
        end
      end
    end

    context 'with distribution event (264 ind2=2)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => '2',
              'subfields' => [
                {
                  'a' => 'Seattle :'
                },
                {
                  'b' => 'Iverson Company,'
                },
                {
                  'c' => '[2009]'
                }
              ]
            } }
          ]
        }
      end

      it 'returns distribution event' do
        expect(build).to eq [{
          type: 'distribution',
          location: [{ value: 'Seattle' }],
          contributor: [{ name: [{ value: 'Iverson Company' }], role: [{ value: 'distributor' }] }],
          date: [{ value: '[2009]', type: 'distribution' }]
        }]
      end
    end

    context 'with manufacture event (264 ind2=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => '3',
              'subfields' => [
                {
                  'a' => 'Cambridge :'
                },
                {
                  'b' => 'Kinsey Printing Company,'
                },
                {
                  'c' => '[2010]'
                }
              ]
            } }
          ]
        }
      end

      it 'returns manufacture event' do
        expect(build).to eq [{
          type: 'manufacture',
          location: [{ value: 'Cambridge' }],
          contributor: [{ name: [{ value: 'Kinsey Printing Company' }], role: [{ value: 'manufacturer' }] }],
          date: [{ value: '[2010]', type: 'manufacture' }]
        }]
      end
    end

    context 'with copyright event (264 ind2=4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => '4',
              'subfields' => [
                {
                  'c' => '℗2017'
                }
              ]
            } }
          ]
        }
      end

      it 'returns copyright event' do
        expect(build).to eq [{
          type: 'copyright notice',
          note: [{ value: '℗2017', type: 'copyright statement' }]
        }]
      end
    end

    context 'with unspecified event (264 ind2 blank)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'New York :'
                },
                {
                  'b' => 'Fifty-three studio,'
                },
                {
                  'c' => '2018.'
                }
              ]
            } }
          ]
        }
      end

      it 'returns untyped event' do
        expect(build).to eq [{
          location: [{ value: 'New York' }],
          contributor: [{ name: [{ value: 'Fifty-three studio' }] }],
          date: [{ value: '2018' }]
        }]
      end
    end

    context 'with publication, distribution, and copyright events' do
      # See a10619029
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
              'ind1' => ' ',
              'ind2' => '1',
              'subfields' => [
                {
                  'a' => '[Oak Ridge, Tenn.] :'
                },
                {
                  'b' => 'Oak Ridge National Laboratory,'
                },
                {
                  'c' => '[2014]'
                }
              ]
            } },
            { '264' => {
              'ind1' => ' ',
              'ind2' => '2',
              'subfields' => [
                {
                  'a' => 'Minneapolis, MN :'
                },
                {
                  'b' => 'East View Information Services, '
                },
                {
                  'c' => '[2014]'
                }
              ]
            } },
            { '264' => {
              'ind1' => ' ',
              'ind2' => '4',
              'subfields' => [
                {
                  'c' => '©2014 '
                }
              ]
            } }
          ]
        }
      end

      it 'returns publication event with multiple publishers' do
        expect(build).to eq [
          {
            type: 'publication',
            location: [{ value: '[Oak Ridge, Tenn.]' }],
            contributor: [
              { name: [{ value: 'Oak Ridge National Laboratory' }], role: [{ value: 'publisher' }] }
            ],
            date: [{ value: '[2014]', type: 'publication' }]
          },
          {
            type: 'distribution',
            location: [
              {
                value: 'Minneapolis, MN'
              }
            ],
            contributor: [
              {
                role: [
                  {
                    value: 'distributor'
                  }
                ],
                name: [
                  {
                    value: 'East View Information Services'
                  }
                ]
              }
            ],
            date: [
              {
                value: '[2014]',
                type: 'distribution'
              }
            ]
          },
          {
            type: 'copyright notice',
            note: [
              {
                value: '©2014 ',
                type: 'copyright statement'
              }
            ]
          }
        ]
      end
    end

    context 'with edition event (250)' do
      context 'with multiple subfields' do
        let(:marc_hash) do
          {
            'fields' => [
              { '250' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Ninth edition /'
                  },
                  {
                    'b' => 'Jonathan S. Abramowitz, University of North Carolina at Chapel Hill, Mitchell J. Prinstein, University of North Carolina at Chapel Hill, Timothy J. Trull, University of Missouri-Columbia.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns publication event with edition note' do
          expect(build).to eq [{
            type: 'publication',
            note: [{
              type: 'edition',
              value: 'Ninth edition / Jonathan S. Abramowitz, University of North Carolina at Chapel Hill, Mitchell J. Prinstein, University of North Carolina at Chapel Hill, Timothy J. Trull, University of Missouri-Columbia.'
            }]
          }]
        end
      end

      context 'with a multiple scripts' do
        let(:marc_hash) do
          {
            'fields' => [
              { '250' => {
                  'ind1' => ' ',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-01'
                    },
                    {
                      'a' => 'Rev. 2nd ed.'
                    }
                  ]
                },
                '880' => {
                  'ind1' => ' ',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '250-01/(N'
                    },
                    {
                      'a' => 'Пересмотр. 2-e изд.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns publication event with edition note' do
          expect(build).to eq [{
            type: 'publication',
            note: [{
              type: 'edition',
              value: 'Rev. 2nd ed.'
            }]
          }, {
            type: 'publication',
            note: [{
              type: 'edition',
              value: 'Пересмотр. 2-e изд.'
            }]
          }]
        end
      end
    end

    context 'with frequency event (310$ab)' do
      # see a493225
      let(:marc_hash) do
        {
          'fields' => [
            { '310' => {
              'ind1' => ' ',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Monthly'
                },
                {
                  'b' => '<Apr. 1988->'
                }
              ]
            } }
          ]
        }
      end

      it 'returns publication event with frequency note' do
        expect(build).to eq [{
          type: 'publication',
          note: [{ value: 'Monthly <Apr. 1988->', type: 'frequency' }]
        }]
      end
    end

    context 'with former frequency event (321$ab)' do
      # see a11632102
      let(:marc_hash) do
        {
          'fields' => [
            {
              '321' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Biweekly,'
                  },
                  {
                    'b' => '1939-June 1946'
                  }
                ]
              }
            },
            {
              '321' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Weekly or biweekly,'
                  },
                  {
                    'b' => 'Dec. 11, 1937-1938'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns publication event with frequency note' do
        expect(build).to eq [{
          type: 'publication',
          note: [{ value: 'Biweekly, 1939-June 1946', type: 'frequency' }, { value: 'Weekly or biweekly, Dec. 11, 1937-1938', type: 'frequency' }]
        }]
      end
    end

    context 'with issuance event (334)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '334' => {
              'ind1' => ' ',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'single unit'
                }
              ]
            } }
          ]
        }
      end

      it 'returns event with issuance note' do
        expect(build).to eq [{
          note: [{ value: 'single unit', type: 'issuance' }]
        }]
      end
    end

    context 'with multiple scripts event (264/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '264' => {
                'ind1' => ' ',
                'ind2' => '1',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'a' => 'Moskva :'
                  },
                  {
                    'b' => 'Izdatelʹstvo "Vesʹ Mir",'
                  },
                  {
                    'c' => '2019.'
                  }
                ]
              },
              '880' => {
                'ind1' => ' ',
                'ind2' => '1',
                'subfields' => [
                  {
                    '6' => '264-03'
                  },
                  {
                    'a' => 'Москва :'
                  },
                  {
                    'b' => 'Издательство "Весь Мир",'
                  },
                  {
                    'c' => '2019.'
                  }
                ]
              } }
          ]
        }
      end

      it 'returns separate events for each script' do
        expect(build).to eq [
          {
            type: 'publication',
            location: [{ value: 'Moskva' }],
            contributor: [{ name: [{ value: 'Izdatelʹstvo "Vesʹ Mir"' }], role: [{ value: 'publisher' }] }],
            date: [{ value: '2019', type: 'publication' }]
          },
          {
            type: 'publication',
            location: [{ value: 'Москва' }],
            contributor: [{ name: [{ value: 'Издательство "Весь Мир"' }], role: [{ value: 'publisher' }] }],
            date: [{ value: '2019', type: 'publication' }]
          }
        ]
      end
    end

    context 'with encoded single publication date (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057nam a2200601Ii 4500',
          'fields' => [
            { '008' => '190904t20192018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns publication event with encoded date' do
        expect(build).to eq [{
          type: 'publication',
          date: [{ value: '2019', type: 'publication', encoding: { code: 'marc' } }]
        }]
      end
    end

    context 'with encoded single creation date (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057ndm a2200601Ii 4500',
          'fields' => [
            { '008' => '190904e20192018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns creation event with encoded date' do
        expect(build).to eq [{
          type: 'creation',
          date: [{ value: '2019', type: 'creation', encoding: { code: 'marc' } }]
        }]
      end
    end

    context 'with encoded multiple publication dates (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057ncm a2200601Ii 4500',
          'fields' => [
            { '008' => '190904m20172018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns publication event with multiple encoded dates' do
        expect(build).to eq [{
          type: 'publication',
          date: [
            { value: '2017', type: 'publication', encoding: { code: 'marc' } },
            { value: '2018', type: 'publication', encoding: { code: 'marc' } }
          ]
        }]
      end
    end

    context 'with encoded multiple creation dates (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057nfm a2200601Ii 4500',
          'fields' => [
            { '008' => '190904m20172018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns creation event with multiple encoded dates' do
        expect(build).to eq [{
          type: 'creation',
          date: [
            { value: '2017', type: 'creation', encoding: { code: 'marc' } },
            { value: '2018', type: 'creation', encoding: { code: 'marc' } }
          ]
        }]
      end
    end

    context 'with encoded publication date range (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057nem a2200601Ii 4500',
          'fields' => [
            { '008' => '190904c20172018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns publication event with encoded date range' do
        expect(build).to eq [{
          type: 'publication',
          date: [{
            structuredValue: [
              { value: '2017', type: 'start' },
              { value: '2018', type: 'end' }
            ],
            type: 'publication',
            encoding: { code: 'marc' }
          }]
        }]
      end
    end

    context 'with encoded creation date range (008)' do
      let(:marc_hash) do
        {
          'leader' => '04057ntm a2200601Ii 4500',
          'fields' => [
            { '008' => '190904d20172018ru            000 0 rusod' }
          ]
        }
      end

      it 'returns creation event with encoded date range' do
        expect(build).to eq [{
          type: 'creation',
          date: [{
            structuredValue: [
              { value: '2017', type: 'start' },
              { value: '2018', type: 'end' }
            ],
            type: 'creation',
            encoding: { code: 'marc' }
          }]
        }]
      end
    end

    context 'with encoded questionable date range (008)' do
      # See a11696300
      let(:marc_hash) do
        {
          'leader' => '01976njm a2200469Ii 4500',
          'fields' => [
            { '008' => '151117q19601965nyumunn n spa d' }
          ]
        }
      end

      it 'returns publication event with qualifed date range' do
        expect(build).to eq [{
          type: 'publication',
          date: [{
            structuredValue: [
              { value: '1960', type: 'start' },
              { value: '1965', type: 'end' }
            ],
            type: 'publication',
            qualifier: 'questionable',
            encoding: { code: 'marc' }
          }]
        }]
      end
    end

    context 'with unknown date (008/06 = n)' do
      # see a12721687
      let(:marc_hash) do
        {
          'leader' => '01976njm a2200469Ii 4500',
          'fields' => [
            { '008' => '180724n eng u' }
          ]
        }
      end

      it 'returns nothing' do
        expect(build).to eq []
      end
    end

    context 'with invalid questionable date (008/06 = q)' do
      # see a11460955
      let(:marc_hash) do
        {
          'leader' => '01976njm a2200469Ii 4500',
          'fields' => [
            { '008' => '170308q1835    enkbd     a   o 0   eng d' }
          ]
        }
      end

      it 'returns nothing' do
        expect(build).to eq []
      end
    end
  end
end
