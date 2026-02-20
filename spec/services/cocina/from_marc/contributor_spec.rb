# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Contributor do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:require_title) { true }
    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with Person primary (100 ind1=1)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '100' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Sayers, Dorothy L.'
                },
                {
                  'q' => '(Dorothy Leigh),'
                },
                {
                  'd' => '1893-1957.'
                },
                {
                  '0' => '(SIRSI)100978'
                }
              ]
            } }
          ]
        }
      end

      it 'returns person primary contributor' do
        expect(build).to eq [{ type: 'person', status: 'primary',
                               name: [{ value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957.' }] }]
      end
    end

    context 'with Family primary (100 ind1=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '100' => {
              'ind1' => '3',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Packard family.'
                }
              ]
            } }
          ]
        }
      end

      it 'returns family primary contributor' do
        expect(build).to eq [{ type: 'family', status: 'primary', name: [{ value: 'Packard family.' }] }]
      end
    end

    context 'with Organization primary (110)' do
      context 'with one script' do
        let(:marc_hash) do
          {
            'fields' => [
              { '110' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Ghana.'
                  },
                  {
                    '0' => '(SIRSI)168717'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns organization primary contributor' do
          expect(build).to eq [{ type: 'organization', status: 'primary', name: [{ value: 'Ghana.' }] }]
        end
      end

      context 'with a role' do
        let(:marc_hash) do
          {
            'fields' => [
              { '110' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'United States.'
                  },
                  {
                    'b' => 'Office of the Inspector General for Tax Administration,'
                  },
                  {
                    'e' => 'issuing body.'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns organization with a role' do
          expect(build).to eq [{
            type: 'organization', status: 'primary',
            name: [{ value: 'United States. Office of the Inspector General for Tax Administration,' }],
            role: [{ value: 'issuing body' }]
          }]
        end
      end

      context 'with multiple scripts (110/880)' do
        # See a3940765
        let(:marc_hash) do
          {
            'fields' => [
              { '110' => {
                  'ind1' => '1',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-01'
                    },
                    {
                      'a' => 'United Arab Republic.'
                    },
                    {
                      'b' => 'Idārat al-Taʻbiʼah al-ʻĀmmah.'
                    },
                    {
                      '0' => 'http://id.loc.gov/authorities/names/n50078747'
                    }
                  ]
                },
                '880' => {
                  'ind1' => '1',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6': '110-01//r'
                    },
                    {
                      'a' => 'ادارة التعبئة العامة.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns organization primary contributor' do
          expect(build).to eq [
            { type: 'organization', status: 'primary',
              name: [{ value: 'United Arab Republic. Idārat al-Taʻbiʼah al-ʻĀmmah.' }] },
            { type: 'organization', name: [{ value: 'ادارة التعبئة العامة.' }] }
          ]
        end
      end
    end

    context 'with meeting primary (111)' do
      context 'with one script' do
        let(:marc_hash) do
          {
            'fields' => [
              { '111' => {
                'ind1' => '2',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'SIGGRAPH (Conference)'
                  },
                  {
                    'n' => '(29th :'
                  },
                  {
                    'd' => '2002 :'
                  },
                  {
                    'c' => 'San Antonio, Tex.)'
                  },
                  {
                    '0' => '(SIRSI)566144'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns event primary contributor' do
          expect(build).to eq [{ type: 'event', status: 'primary',
                                 name: [{ value: 'SIGGRAPH (Conference) (29th : 2002 : San Antonio, Tex.)' }] }]
        end
      end

      context 'with multiple scripts (111/880)' do
        let(:marc_hash) do
          {
            'fields' => [
              { '111' => {
                  'ind1' => '2',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-1'
                    },
                    {
                      'a' => 'Miz͡hnarodna naukovo-praktychna konferent͡sii͡a "Konstantynopolʹsʹkyĭ patriarkhat v istoriï Ukraïny : mynule, suchasne, maĭbutni͡e"'
                    },
                    {
                      'd' => '(2016 :'
                    },
                    {
                      'c' => 'Kyïv (Ukraine),'
                    },
                    {
                      'j' => 'author.'
                    }
                  ]
                },
                '880' => {
                  'ind1' => '2',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '111-01'
                    },
                    {
                      'a' => 'Міжнародна науково-практична конференція "Константинопольський патріархат в історії України : минуле, сучасне, майбутнє"'
                    },
                    {
                      'd' => '(2016 :'
                    },
                    {
                      'c' => 'Київ (Украіне)),'
                    },
                    {
                      'j' => 'author.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns event primary contributor' do
          expect(build).to eq [
            { type: 'event', status: 'primary',
              name: [{ value: 'Miz͡hnarodna naukovo-praktychna konferent͡sii͡a "Konstantynopolʹsʹkyĭ patriarkhat v istoriï Ukraïny : mynule, suchasne, maĭbutni͡e" (2016 : Kyïv (Ukraine)' }], role: [{ value: 'author' }] },
            { type: 'event',
              name: [{ value: 'Міжнародна науково-практична конференція "Константинопольський патріархат в історії України : минуле, сучасне, майбутнє" (2016 : Київ (Украіне))' }], role: [{ value: 'author' }] }
          ]
        end
      end
    end

    context 'with Person contributor (700 ind1=1) that has a $c (Titles and other words associated with a name)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Street, Stephen'
                },
                {
                  'c' => '(Double bassist).'
                }
              ]
            } }
          ]
        }
      end

      it 'returns person contributor' do
        expect(build).to eq [{ type: 'person', name: [{ value: 'Street, Stephen (Double bassist).' }] }]
      end
    end

    context 'with multiple Person contributors (700 ind1=1)' do
      # See 11894313

      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'De Crescenzo, Vincenzo,'
                },
                {
                  'd' => '1875-1964,'
                },
                {
                  'e' => 'composer.'
                }
              ]
            } },
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Hubbell, Raymond,'
                },
                {
                  'd' => '1879-1954,'
                },
                {
                  'e' => 'composer.'
                }
              ]
            } }
          ]
        }
      end

      it 'returns person contributors' do
        expect(build).to eq [
          { type: 'person', name: [{ value: 'De Crescenzo, Vincenzo, 1875-1964' }], role: [{ value: 'composer' }] },
          { type: 'person', name: [{ value: 'Hubbell, Raymond, 1879-1954' }], role: [{ value: 'composer' }] }
        ]
      end
    end

    context 'with Family contributor (700 ind1=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '3',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Gouzigian family.'
                }
              ]
            } }
          ]
        }
      end

      it 'returns family contributor' do
        expect(build).to eq [{ type: 'family', name: [{ value: 'Gouzigian family.' }] }]
      end
    end

    context 'with Organization contributor (710)' do
      context 'with one script' do
        let(:marc_hash) do
          {
            'fields' => [
              { '710' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Ghana'
                  },
                  {
                    'b' => 'Ministry of Tourism (2009-2013)'
                  },
                  {
                    '0' => '(SIRSI)168717'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns organization contributor' do
          expect(build).to eq [{ type: 'organization', name: [{ value: 'Ghana Ministry of Tourism (2009-2013)' }] }]
        end
      end

      context 'with multiple scripts (710/880)' do
        let(:marc_hash) do
          {
            'fields' => [
              { '710' => {
                  'ind1' => '1',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-01'
                    },
                    {
                      'a' => 'United Arab Republic.'
                    },
                    {
                      'b' => 'Idārat al-Taʻbiʼah al-ʻĀmmah.'
                    },
                    {
                      '0' => 'http://id.loc.gov/authorities/names/n50078747'
                    }
                  ]
                },
                '880' => {
                  'ind1' => '1',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '700-05//r'
                    },
                    {
                      'a' => 'ادارة التعبئة العامة.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns separate contributors for each script with different roles' do
          expect(build).to eq [
            { type: 'organization', name: [{ value: 'United Arab Republic. Idārat al-Taʻbiʼah al-ʻĀmmah.' }] },
            { type: 'organization', name: [{ value: 'ادارة التعبئة العامة.' }] }
          ]
        end
      end
    end

    context 'with meeting contributor (711)' do
      context 'with one script' do
        let(:marc_hash) do
          {
            'fields' => [
              { '711' => {
                'ind1' => '2',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Simulation Solutions Conference.'
                  },
                  {
                    '0' => 'http://id.loc.gov/authorities/names/no2005090352'
                  }
                ]
              } }
            ]
          }
        end

        it 'returns event contributor' do
          expect(build).to eq [{ type: 'event', name: [{ value: 'Simulation Solutions Conference.' }] }]
        end
      end

      context 'with multiple scripts (711/880)' do
        let(:marc_hash) do
          {
            'fields' => [
              { '711' => {
                  'ind1' => '2',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '880-1'
                    },
                    {
                      'a' => 'Miz͡hnarodna naukovo-praktychna konferent͡sii͡a "Konstantynopolʹsʹkyĭ patriarkhat v istoriï Ukraïny : mynule, suchasne, maĭbutni͡e"'
                    },
                    {
                      'd' => '(2016 :'
                    },
                    {
                      'c' => 'Kyïv (Ukraine),'
                    },
                    {
                      'j' => 'author.'
                    }
                  ]
                },
                '880' => {
                  'ind1' => '2',
                  'ind2' => ' ',
                  'subfields' => [
                    {
                      '6' => '111-01'
                    },
                    {
                      'a' => 'Міжнародна науково-практична конференція "Константинопольський патріархат в історії України : минуле, сучасне, майбутнє"'
                    },
                    {
                      'd' => '(2016 :'
                    },
                    {
                      'c' => 'Київ (Украіне)),'
                    },
                    {
                      'j' => 'author.'
                    }
                  ]
                } }
            ]
          }
        end

        it 'returns event contributor' do
          expect(build).to eq [
            { type: 'event',
              name: [{ value: 'Miz͡hnarodna naukovo-praktychna konferent͡sii͡a "Konstantynopolʹsʹkyĭ patriarkhat v istoriï Ukraïny : mynule, suchasne, maĭbutni͡e" (2016 : Kyïv (Ukraine)' }], role: [{ value: 'author' }] },
            { type: 'event',
              name: [{ value: 'Міжнародна науково-практична конференція "Константинопольський патріархат в історії України : минуле, сучасне, майбутнє" (2016 : Київ (Украіне))' }], role: [{ value: 'author' }] }
          ]
        end
      end
    end

    context 'with Person contributor (720 ind1=1)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '720' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Blacklock, Joseph'
                }
              ]
            } }
          ]
        }
      end

      it 'returns person contributor' do
        expect(build).to eq [{ type: 'person', name: [{ value: 'Blacklock, Joseph' }] }]
      end
    end

    context 'with Untyped contributor (720 ind1 blank)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '720' => {
              'ind1' => ' ',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Vonderrohe, Robert, 1934-'
                }
              ]
            } }
          ]
        }
      end

      it 'returns untyped contributor' do
        expect(build).to eq [{ name: [{ value: 'Vonderrohe, Robert, 1934-' }] }]
      end
    end

    context 'with Contributor with role terms (100 with $e)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '100' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Wagner, Richard,'
                },
                {
                  'd' => '1813-1883,'
                },
                {
                  'e' => 'composer,'
                },
                {
                  'e' => 'librettist.'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/n79089831'
                },
                {
                  '1' => 'https://id.oclc.org/worldcat/entity/E39PBJvMCYbW9m9kmHKrwph4MP'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor with role terms' do
        expect(build).to eq [{ type: 'person', status: 'primary', name: [{ value: 'Wagner, Richard, 1813-1883' }],
                               role: [{ value: 'composer' }, { value: 'librettist' }] }]
      end
    end

    context 'with Contributor with different role term and code (700 with $e and $4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Cao, Rosa,'
                },
                {
                  'e' => 'degree committee member.'
                },
                {
                  '4' => 'ths'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/no2019143165'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor with both role term and mapped code' do
        expect(build).to eq [{ type: 'person', name: [{ value: 'Cao, Rosa' }],
                               role: [{ value: 'degree committee member' }, { value: 'thesis advisor' }] }]
      end
    end

    context 'with Contributor with same role term and code (deduplication)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Cao, Rosa,'
                },
                {
                  'e' => 'degree committee member.'
                },
                {
                  '4' => 'dgc'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/no2019143165'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor with deduplicated role terms' do
        expect(build).to eq [{ type: 'person', name: [{ value: 'Cao, Rosa' }],
                               role: [{ value: 'degree committee member' }] }]
      end
    end

    context 'with Event contributor with role term (711 with $j)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '711' => {
              'ind1' => '2',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Simulation Solutions Conference.'
                },
                {
                  'j' => 'creator.'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/no2005090352'
                }
              ]
            } }
          ]
        }
      end

      it 'returns event contributor with role' do
        expect(build).to eq [{ type: 'event', name: [{ value: 'Simulation Solutions Conference.' }],
                               role: [{ value: 'creator' }] }]
      end
    end

    context 'with Contributor with invalid role code' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Cao, Rosa,'
                },
                {
                  'e' => 'degree committee member.'
                },
                {
                  '4' => 'tsh'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/no2019143165'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor ignoring invalid role code' do
        expect(build).to eq [{ type: 'person', name: [{ value: 'Cao, Rosa' }],
                               role: [{ value: 'degree committee member' }] }]
      end
    end

    context 'with Contributor with ORCID identifier' do
      # based on in00000870077
      let(:marc_hash) do
        {
          'fields' => [
            { '100' => {
              'ind1' => '1',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Velez, Vannessa Naomi.'
                },
                {
                  '1' => 'https://orcid.org/0009-0005-5256-569X'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor with ORCID identifier' do
        expect(build).to eq [{
          type: 'person', status: 'primary',
          name: [{ value: 'Velez, Vannessa Naomi.' }],
          identifier: [{ uri: 'https://orcid.org/0009-0005-5256-569X', type: 'ORCID' }]
        }]
      end
    end

    context 'with Contributor with other identifier' do
      let(:marc_hash) do
        {
          'fields' => [
            { '710' => {
              'ind1' => '2',
              'ind2' => ' ',
              'subfields' => [
                {
                  'a' => 'Stanford University.'
                },
                {
                  'b' => 'School of Humanities and Sciences.'
                },
                {
                  '0' => 'http://id.loc.gov/authorities/names/no2009155385'
                },
                {
                  '1' => 'https://ror.org/00f54p054'
                }
              ]
            } }
          ]
        }
      end

      it 'returns contributor with URI identifier' do
        expect(build).to eq [{ type: 'organization',
                               name: [{ value: 'Stanford University. School of Humanities and Sciences.' }], identifier: [{ uri: 'https://ror.org/00f54p054' }] }]
      end
    end

    context 'with Contributor in multiple scripts (100/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '100' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'a' => 'Smagina, S. A.'
                  },
                  {
                    'e' => 'author.'
                  },
                  {
                    '0' => 'http://id.loc.gov/authorities/names/no2011031220'
                  },
                  {
                    '0' => '(SIRSI)3726444'
                  }
                ]
              },
              '880' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '100-01'
                  },
                  {
                    'a' => 'Смагина, С. А,'
                  },
                  {
                    'e' => 'author.'
                  }
                ]
              } }
          ]
        }
      end

      it 'returns separate contributors for each script' do
        expect(build).to eq [
          { type: 'person', name: [{ value: 'Smagina, S. A.' }], role: [{ value: 'author' }], status: 'primary' },
          { type: 'person', name: [{ value: 'Смагина, С. А' }], role: [{ value: 'author' }] }
        ]
      end
    end

    context 'with Contributor in multiple scripts (700/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '700' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'a' => 'Lukin, Alexander,'
                  },
                  {
                    'e' => 'editor.'
                  },
                  {
                    '0' => 'http://id.loc.gov/authorities/names/nb99131940'
                  },
                  {
                    '0' => '(SIRSI)1666028'
                  }
                ]
              },
              '880' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '700-05'
                  },
                  {
                    'a' => 'Лукин, Александр ,'
                  },
                  {
                    'e' => 'author.'
                  }
                ]
              } }
          ]
        }
      end

      it 'returns separate contributors for each script with different roles' do
        expect(build).to eq [
          { type: 'person', name: [{ value: 'Lukin, Alexander' }], role: [{ value: 'editor' }] },
          { type: 'person', name: [{ value: 'Лукин, Александр' }], role: [{ value: 'author' }] }
        ]
      end
    end
  end
end
