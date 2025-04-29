# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  # https://argo.stanford.edu/view/mn760md9509
  # https://argo.stanford.edu/view/sf449my9678
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge({ purl: "https://purl.stanford.edu/#{bare_druid}" }),
      identification: identification
    )
  end
  let(:identification) do
    {
      catalogLinks: [
        {
          catalog: 'folio',
          refresh: true,
          catalogRecordId: 'in1234',
          partLabel: 'Part 1',
          sortKey: '1'
        }
      ],
      sourceId: 'sul1:123'
    }
  end
  let(:description) do
    {
      title: [
        {
          structuredValue: [
            {
              value: 'The',
              type: 'nonsorting characters'
            },
            {
              value: 'complete works of Henry George',
              type: 'main title'
            }
          ],
          note: [
            {
              value: '4',
              type: 'nonsorting character count'
            }
          ]
        }
      ],
      contributor: [
        {
          name: [{
            structuredValue: [
              {
                value: 'George, Henry',
                type: 'name'
              },
              {
                value: '1839-1897',
                type: 'life dates'
              }
            ]
          }],
          type: 'person',
          role: [{
            value: 'creator',
            source: {
              code: 'marcrelator'
            }
          }],
          identifier: [
            {
              value: '0000-1111-2222-3333',
              type: 'ORCID',
              source: {
                uri: 'https://orcid.org'
              }
            }
          ]
        },
        {
          name: [
            {
              structuredValue: [
                {
                  value: 'George, Henry',
                  type: 'name'
                },
                {
                  value: '1862-1916',
                  type: 'life dates'
                }
              ]
            }
          ],
          type: 'person'
        },
        {
          name: [
            {
              structuredValue: [
                {
                  value: 'George, Bush',
                  type: 'name'
                }
              ]
            }
          ],
          type: 'person',
          identifier: [
            {
              uri: 'https://sandbox.orcid.org/1111-2222-3333-4444',
              type: 'ORCID',
              source: {
                code: 'orcid'
              }
            }
          ]
        },
        {
          name: [
            {
              value: 'Wiles, Simon'
            }
          ],
          type: 'person',
          role: [
            {
              value: 'Data Curator',
              source: {
                code: 'datacite'
              }
            }
          ],
          identifier: [
            {
              value: '0000-0001-5321-289X',
              type: 'ORCID',
              source: {
                code: 'orcid'
              }
            }
          ]
        }
      ],
      event: [{
        type: 'publication',
        date: [
          {
            value: '1911',
            status: 'primary',
            type: 'publication',
            encoding: {
              code: 'marc'
            }
          }
        ],
        contributor: [{
          name: [{
            value: 'Doubleday, Page'
          }],
          type: 'organization',
          role: [{
            value: 'publisher',
            code: 'pbl',
            uri: 'http://id.loc.gov/vocabulary/relators/pbl',
            source: {
              code: 'marcrelator',
              uri: 'http://id.loc.gov/vocabulary/relators/'
            }
          }]
        }],
        location: [
          {
            value: 'Garden City, N. Y'
          },
          {
            code: 'xx',
            source: {
              code: 'marccountry'
            }
          }
        ],
        note: [
          {
            value: '[Library ed.]',
            type: 'edition'
          },
          {
            value: 'monographic',
            type: 'issuance',
            source: {
              value: 'MODS issuance terms'
            }
          }
        ]
      }],
      form: [
        {
          value: 'text',
          type: 'resource type',
          source: {
            value: 'MODS resource types'
          }
        },
        {
          value: 'electronic',
          type: 'form',
          source: {
            code: 'marcform'
          }
        },
        {
          value: 'preservation',
          type: 'reformatting quality',
          source: {
            value: 'MODS reformatting quality terms'
          }
        },
        {
          value: 'reformatted digital',
          type: 'digital origin',
          source: {
            value: 'MODS digital origin terms'
          }
        }
      ],
      language: [{
        code: 'eng',
        source: {
          code: 'iso639-2b'
        }
      }],
      note: [
        {
          value: 'On cover: Complete works of Henry George. Fels fund. Library edition.'
        },
        {
          value: 'I. Progress and poverty.--II. Social problems.--III. The land question. Property in land. blah blah',
          type: 'table of contents'
        }
      ],
      identifier: [{
        value: 'druid:pz263ny9658',
        type: 'local',
        displayLabel: 'SUL Resource ID'
      }],
      subject: [
        {
          structuredValue: [
            {
              value: 'Economics',
              type: 'topic'
            },
            {
              value: '1800-1900',
              type: 'time'
            }
          ],
          source: {
            code: 'lcsh'
          }
        },
        {
          structuredValue: [
            {
              value: 'Economics',
              type: 'topic'
            },
            {
              value: 'Europe',
              type: 'place'
            }
          ],
          source: {
            code: 'lcsh'
          }
        },
        {
          value: 'cats',
          type: 'topic'
        }
      ],
      purl: 'https://purl.stanford.edu/qy781dy0220',
      access: {
        physicalLocation: [{
          value: 'Stanford University Libraries'
        }],
        digitalRepository: [{
          value: 'Stanford Digital Repository'
        }]
      },
      relatedResource: [
        {
          type: 'has original version',
          form: [
            {
              value: 'print',
              type: 'form',
              source: {
                code: 'marcform'
              }
            },
            {
              value: '10 v. fronts (v. 1-9) ports. 21 cm.',
              type: 'extent'
            }
          ],
          adminMetadata: {
            contributor: [{
              name: [{
                code: 'YNG',
                source: {
                  code: 'marcorg'
                }
              }],
              type: 'organization',
              role: [{
                value: 'original cataloging agency'
              }]
            }],
            event: [
              {
                type: 'creation',
                date: [{
                  value: '731210',
                  encoding: {
                    code: 'marc'
                  }
                }]
              },
              {
                type: 'modification',
                date: [{
                  value: '19900625062034.0',
                  encoding: {
                    code: 'iso8601'
                  }
                }]
              }
            ],
            identifier: [
              {
                value: '68184',
                type: 'SUL catalog key'
              },
              {
                value: '757655',
                type: 'OCLC'
              }
            ]
          }
        },
        {
          purl: 'https://purl.stanford.edu/pz263ny9658',
          access: {
            digitalRepository: [
              {
                value: 'Stanford Digital Repository'
              }
            ]
          }
        }
      ],
      adminMetadata: {
        contributor: [{
          name: [{
            value: 'DOR_MARC2MODS3-3.xsl Revision 1.1'
          }]
        }],
        event: [{
          type: 'creation',
          date: [{
            value: '2011-02-25T18:20:23.132-08:00',
            encoding: {
              code: 'iso8601'
            }
          }]
        }],
        identifier: [{
          value: '36105010700545',
          type: 'Data Provider Digital Object Identifier'
        }]
      }
    }
  end

  describe '#to_solr' do
    it 'populates expected fields' do
      all_search_text = 'The complete works of Henry George 4 George, Henry 1839-1897 George, Henry 1862-1916 ' \
                        'George, Bush Wiles, Simon Doubleday, Page [Library ed.] monographic Garden City, N. Y text ' \
                        'electronic preservation reformatted digital On cover: Complete works of Henry George. Fels ' \
                        'fund. Library edition. I. Progress and poverty.--II. Social problems.--III. The land ' \
                        'question. Property in land. blah blah print 10 v. fronts (v. 1-9) ports. 21 cm. Economics ' \
                        '1800-1900 Economics Europe cats'
      expect(doc).to eq(
        'descriptive_tiv' => all_search_text,
        'descriptive_teiv' => all_search_text,
        'descriptive_text_nostem_i' => all_search_text,
        'sw_language_ssim' => ['English'],
        'sw_format_ssim' => ['Book'],
        'mods_typeOfResource_ssim' => ['text'],
        'sw_subject_temporal_ssim' => ['1800-1900'],
        'sw_subject_geographic_ssim' => ['Europe'],
        'sw_pub_date_facet_ssi' => '1911',
        'author_display_ss' => 'George, Henry, 1839-1897',
        'author_text_nostem_im' => 'George, Henry, 1839-1897',
        'contributor_text_nostem_im' => ['George, Henry, 1839-1897', 'George, Henry, 1862-1916', 'George, Bush',
                                         'Wiles, Simon'],
        'main_title_tenim' => ['The complete works of Henry George'],
        'full_title_tenim' => ['The complete works of Henry George'],
        # 'additional_titles_tenim' => '', # not populated by the example; see indexer_spec instead
        'display_title_ss' => 'The complete works of Henry George, Part 1',
        # 'originInfo_date_created_tesim' => '', # not populated by the example; see indexer_spec instead
        'originInfo_publisher_tesim' => 'Doubleday, Page',
        'topic_ssim' => %w[Economics cats],
        'topic_tesim' => %w[cats Economics],
        'originInfo_place_placeTerm_tesim' => 'Garden City, N. Y',
        'contributor_orcids_ssim' => ['https://orcid.org/0000-1111-2222-3333',
                                      'https://sandbox.orcid.org/1111-2222-3333-4444', 'https://orcid.org/0000-0001-5321-289X']
      )
    end
    # rubocop:enable Style/StringHashKeys

    it 'does not include empty values' do
      doc.keys.sort_by(&:to_s).each do |k|
        expect(doc).to include(k)
        expect(doc).to match hash_excluding(k => nil)
        expect(doc).to match hash_excluding(k => [])
      end
    end

    context 'with translated title' do
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  structuredValue: [
                    {
                      value: 'Toldot ha-Yehudim be-artsot ha-Islam',
                      type: 'main title'
                    },
                    {
                      value: 'ha-ʻet ha-ḥadashah-ʻad emtsaʻ ha-meʼah ha-19',
                      type: 'subtitle'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'תולדות היהודים בארצות האיסלאם',
                      type: 'main title'
                    },
                    {
                      value: 'העת החדשה עד אמצע המאה ה־19',
                      type: 'subtitle'
                    }
                  ]
                }
              ]
            },
            {
              value: 'History of the Jews in the Islamic countries',
              type: 'alternative'
            }
          ]
        }
      end

      it 'populates expected fields' do
        all_search_text = 'Toldot ha-Yehudim be-artsot ha-Islam ha-ʻet ' \
                          'ha-ḥadashah-ʻad emtsaʻ ha-meʼah ha-19 ' \
                          'תולדות היהודים בארצות האיסלאם ' \
                          'העת החדשה עד אמצע המאה ה־19 History of the ' \
                          'Jews in the Islamic countries'
        # rubocop:disable Style/StringHashKeys
        expect(doc).to eq(
          'descriptive_tiv' => all_search_text,
          'descriptive_teiv' => all_search_text,
          'descriptive_text_nostem_i' => all_search_text,
          'main_title_tenim' => ['Toldot ha-Yehudim be-artsot ha-Islam', 'תולדות היהודים בארצות האיסלאם'],
          'full_title_tenim' => ['Toldot ha-Yehudim be-artsot ha-Islam ha-ʻet ha-ḥadashah-ʻad emtsaʻ ha-meʼah ha-19',
                                 'תולדות היהודים בארצות האיסלאם העת החדשה עד אמצע המאה ה־19'],
          'additional_titles_tenim' => ['History of the Jews in the Islamic countries'],
          'display_title_ss' =>
            'Toldot ha-Yehudim be-artsot ha-Islam : ha-ʻet ha-ḥadashah-ʻad emtsaʻ ha-meʼah ha-19, Part 1'
        )
        # rubocop:enable Style/StringHashKeys
      end
    end
  end
end
