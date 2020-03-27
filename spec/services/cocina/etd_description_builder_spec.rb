# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::EtdDescriptionBuilder do
  subject(:description) { described_class.build(item) }

  let(:item) do
    Dor::Etd.new(pid: 'druid:hj456dt5655').tap do |item|
      item.add_datastream(readers_ds)
      item.add_datastream(properties_ds)
    end
  end
  let(:readers_ds) { ActiveFedora::SimpleDatastream.new(nil, 'readers').tap { |ds| ds.content = readers_xml } }
  let(:properties_ds) { ActiveFedora::SimpleDatastream.new(nil, 'properties').tap { |ds| ds.content = properties_xml } }

  let(:readers_xml) do
    <<~XML
      <?xml version="1.0"?>
      <readers>
        <reader>
          <suffix/>
          <univid>03079696</univid>
          <finalreader>Yes</finalreader>
          <name>Duffie, Darrell</name>
          <sunetid>duffie</sunetid>
          <prefix/>
          <readerrole>Advisor</readerrole>
          <type>int</type>
        </reader>
        <reader>
          <suffix/>
          <univid>05357617</univid>
          <finalreader>No</finalreader>
          <name>Strebulaev, Ilya A</name>
          <sunetid>ilyas1</sunetid>
          <prefix/>
          <readerrole>Co-Adv</readerrole>
          <type>int</type>
        </reader>
        <reader>
          <suffix/>
          <univid>09924523</univid>
          <finalreader>No</finalreader>
          <name>Zwiebel, Jeffrey</name>
          <sunetid>zwiebel</sunetid>
          <prefix/>
          <readerrole>Reader</readerrole>
          <type>int</type>
        </reader>
      </readers>
    XML
  end

  let(:properties_xml) do
    <<~XML
      <?xml version="1.0"?>
      <fields>
        <abstract>My dissertation is a combination of three papers that I worked on at various stages of my doctoral studies at Stanford University Graduate School of Business. The central of theme of these papers is dynamic optimality with adjustment costs and gradualness in various economic environments. In all of these papers, I shared various tasks and responsibilities of the research with my coauthors. In Chapter 1, together with Ryota Iijima, I study a model of gradual adjustment in games, in which players can flexibly adjust and monitor their positions up until a deadline. Players' terminal and flow payoffs are influenced by their positions. I show that, unlike in one-shot games, the equilibrium is unique for a broad class of terminal payoffs when players' actions are flexible enough in the presence of (possibly small) noise. In a team-production model, the unique equilibrium selects an outcome that is approximately efficient when adjustment friction is small. I also examine the welfare implications of such gradualness in applications, including team production, hold-up problems, and dynamic contests. In Chapter 2, together with Christopher Hennessy and Ilya Streublaev, I study dynamic capital structure choice with a time-varying tax rate. Absent theoretical guidance, empiricists have been forced to rely upon numerical comparative statics from constant tax rate models in formulating testable implications of tradeoff theory in the context of natural experiments. I fill the theoretical void by solving in closed-form a dynamic tradeoff theoretic model in which corporate taxes follow a (two-state) Markov process with exogenous rate changes. I simulate ideal difference-in-differences estimations, finding that constant tax rate models offer poor guidance regarding testable implications. While constant rate models predict large symmetric responses to rate changes, my model with stochastic tax rates predicts small, asymmetric, and often statistically insignificant responses. Under plausible parameterizations with decade-long regimes, the true underlying theory -- that taxes matter -- is incorrectly rejected in about half of the simulated natural experiments. Moreover, tax response coefficients are actually smaller in simulated economies with larger tax-induced welfare losses. In Chapter 3, which is also joint work with Ryota Iijima, I consider a class of games in which players commonly observe noisy shocks and gradually adjust their actions without observing information about their opponents' behavior. Under a form of richness of the noise process, I prove equilibrium uniqueness when players' adjustment is flexible enough. In the case of potential games, the unique equilibrium approximates the global maximizer of the potential as the friction vanishes.</abstract>
        <cclicense>4</cclicense>
        <cclicensetype>CC Attribution Non-Commercial license</cclicensetype>
        <containscopyright>false</containscopyright>
        <degree>Ph.D.</degree>
        <degreeconfyr>2017</degreeconfyr>
        <department>Business Administration</department>
        <dissertation_id>0000005406</dissertation_id>
        <documentaccess>No</documentaccess>
        <embargo>immediately</embargo>
        <etd_type>Dissertation</etd_type>
        <external_visibility>20</external_visibility>
        <major>Business Administration</major>
        <name>Kasahara, Akitada</name>
        <prefix/>
        <provost>Patricia J. Gumport</provost>
        <ps_career>Graduate School of Business</ps_career>
        <ps_plan>Business Administration</ps_plan>
        <ps_program>Business Administration</ps_program>
        <ps_subplan>Finance</ps_subplan>
        <readeractiondttm>06/02/2017 20:33:37</readeractiondttm>
        <readerapproval>Approved</readerapproval>
        <readercomment/>
        <regactiondttm>06/07/2017 11:05:47</regactiondttm>
        <regapproval>Approved</regapproval>
        <regcomment>Congratulations!</regcomment>
        <schoolname>Graduate School of Business</schoolname>
        <sub>deadline: 2017-06-07</sub>
        <submit_date>1496425544</submit_date>
        <suffix>Jr</suffix>
        <sulicense>true</sulicense>
        <sunetid>akitadak</sunetid>
        <term>1176</term>
        <title>Essays on Game Theory and Corporate Finance</title>
        <univid>05797391</univid>
      </fields>
    XML
  end

  # rubocop:disable Metrics/LineLength
  let(:expected) do
    {
      "title": [
        {
          "value": 'Essays on Game Theory and Corporate Finance',
          "status": 'primary'
        }
      ],
      "contributor": [
        {
          "name": [
            {
              "value": 'Kasahara, Akitada, Jr',
              "type": 'inverted name'
            },
            {
              "structuredValue": [
                {
                  "value": 'Kasahara, Akitada',
                  "type": 'inverted name'
                },
                {
                  "value": 'Jr',
                  "type": 'name suffix'
                }
              ]
            }
          ],
          "type": 'person',
          "status": 'primary',
          "role": [
            {
              "value": 'author',
              "code": 'aut',
              "uri": 'http://id.loc.gov/vocabulary/relators/aut',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            },
            {
              "value": 'author',
              "uri": 'http://rdaregistry.info/Elements/a/P50195',
              "source": {
                "uri": 'http://www.rdaregistry.info/Elements/a/'
              }
            }
          ]
        },
        {
          "name": [
            {
              "value": 'Duffie, Darrell',
              "type": 'inverted name'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'Advisor',
              "source": {
                "value": 'ETD reader roles'
              }
            },
            {
              "value": 'degree supervisor',
              "code": 'dgs',
              "uri": 'http://id.loc.gov/vocabulary/relators/dgs',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            },
            {
              "value": 'degree supervisor',
              "uri": 'http://rdaregistry.info/Elements/a/P50091',
              "source": {
                "uri": 'http://www.rdaregistry.info/Elements/a/'
              }
            }
          ]
        },
        {
          "name": [
            {
              "value": 'Strebulaev, Ilya A',
              "type": 'inverted name'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'Co-Adv',
              "source": {
                "value": 'ETD reader roles'
              }
            },
            {
              "value": 'degree supervisor',
              "code": 'dgs',
              "uri": 'http://id.loc.gov/vocabulary/relators/dgs',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            },
            {
              "value": 'degree supervisor',
              "uri": 'http://rdaregistry.info/Elements/a/P50091',
              "source": {
                "uri": 'http://www.rdaregistry.info/Elements/a/'
              }
            }
          ]
        },
        {
          "name": [
            {
              "value": 'Zwiebel, Jeffrey',
              "type": 'inverted name'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'Reader',
              "source": {
                "value": 'ETD reader roles'
              }
            },
            {
              "value": 'thesis advisor',
              "code": 'ths',
              "uri": 'http://id.loc.gov/vocabulary/relators/ths',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            },
            {
              "value": 'degree committee member',
              "uri": 'http://rdaregistry.info/Elements/a/P50257',
              "source": {
                "uri": 'http://www.rdaregistry.info/Elements/a/'
              }
            }
          ]
        }
      ],
      "event": [
        {
          "type": 'thesis submission',
          "date": [
            {
              "value": '2017'
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "structuredValue": [
                    {
                      "value": 'Stanford University',
                      "type": 'university',
                      "uri": 'http://id.loc.gov/authorities/names/n79054636',
                      "source": {
                        "code": 'lcnaf',
                        "uri": 'http://id.loc.gov/authorities/names/'
                      }
                    },
                    {
                      "value": 'Graduate School of Business',
                      "type": 'school'
                    },
                    {
                      "value": 'Business Administration',
                      "type": 'department'
                    }
                  ]
                }
              ],
              "type": 'organization',
              "role": [
                {
                  "value": 'degree granting institution',
                  "code": 'dgg',
                  "uri": 'http://id.loc.gov/vocabulary/relators/dgg',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  "value": 'degree granting institution',
                  "uri": 'http://rdaregistry.info/Elements/a/P50003',
                  "source": {
                    "uri": 'http://www.rdaregistry.info/Elements/a/'
                  }
                }
              ]
            }
          ]
        },
        {
          "type": 'degree conferral',
          "date": [
            {
              "value": '2017',
              "encoding": %w[edtf w3cdtf marc iso8601]
            }
          ],
          "note": [
            {
              "value": 'Ph.D.',
              "type": 'degree type'
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "value": 'Stanford University',
                  "uri": 'http://id.loc.gov/authorities/names/n79054636',
                  "source": {
                    "code": 'lcnaf',
                    "uri": 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              "type": 'organization',
              "role": [
                {
                  "value": 'degree granting institution',
                  "code": 'dgg',
                  "uri": 'http://id.loc.gov/vocabulary/relators/dgg',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  "value": 'degree granting institution',
                  "uri": 'http://rdaregistry.info/Elements/a/P50003',
                  "source": {
                    "uri": 'http://www.rdaregistry.info/Elements/a/'
                  }
                }
              ]
            }
          ]
        },
        {
          "type": 'publication',
          "date": [
            {
              "value": '2017',
              "encoding": %w[edtf w3cdtf marc iso8601]
            }
          ],
          "location": [
            {
              "value": 'Stanford (Calif.)',
              "uri": 'http://id.loc.gov/authorities/names/n50046557',
              "source": {
                "code": 'lcnaf',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            },
            {
              "value": 'California',
              "code": 'cau',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau',
              "source": {
                "code": 'marccountry',
                "uri": 'http://id.loc.gov/vocabulary/countries/'
              }
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "value": 'Stanford University',
                  "uri": 'http://id.loc.gov/authorities/names/n79054636',
                  "source": {
                    "code": 'lcnaf',
                    "uri": 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              "type": 'organization',
              "role": [
                {
                  "value": 'publisher',
                  "code": 'pbl',
                  "uri": 'http://id.loc.gov/vocabulary/relators/pbl',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                },
                {
                  "value": 'publisher',
                  "uri": 'http://rdaregistry.info/Elements/a/P50203',
                  "source": {
                    "uri": 'http://www.rdaregistry.info/Elements/a/'
                  }
                }
              ]
            }
          ],
          "note": [
            {
              "value": 'monographic',
              "type": 'issuance',
              "uri": 'http://id.loc.gov/vocabulary/issuance/mono',
              "source": {
                "uri": 'http://id.loc.gov/vocabulary/issuance/'
              }
            }
          ],
          "structuredValue": [
            {
              "value": '[Stanford, California]',
              "type": 'publication statement place',
              "standard": ['RDA']
            },
            {
              "value": '[Stanford University]',
              "type": 'publication statement publisher',
              "standard": ['RDA']
            },
            {
              "value": '2017',
              "type": 'publication statement date',
              "standard": ['RDA']
            }
          ]
        },
        {
          "type": 'copyright',
          "date": [
            {
              "value": '2017',
              "encoding": %w[edtf w3cdtf marc iso8601]
            }
          ],
          "structuredValue": [
            {
              "value": '©2017',
              "type": 'copyright statement',
              "standard": ['RDA']
            }
          ]
        }
      ],
      "form": [
        {
          "value": 'computer',
          "type": 'media',
          "uri": 'http://id.loc.gov/vocabulary/mediaTypes/c',
          "source": {
            "code": 'rdamedia',
            "uri": 'http://id.loc.gov/vocabulary/mediaTypes/'
          }
        },
        {
          "value": 'online resource',
          "type": 'carrier',
          "uri": 'http://id.loc.gov/vocabulary/carriers/cr',
          "source": {
            "code": 'rdacarrier',
            "uri": 'http://id.loc.gov/vocabulary/carriers/'
          }
        },
        {
          "value": '1 online resource',
          "type": 'extent',
          "standard": ['RDA']
        },
        {
          "value": 'text',
          "type": 'resource type',
          "source": {
            "value": 'MODS resource type'
          }
        },
        {
          "value": 'text',
          "type": 'content type',
          "uri": 'http://id.loc.gov/vocabulary/contentTypes/txt',
          "source": {
            "code": 'rdacontent',
            "uri": 'http://id.loc.gov/vocabulary/contentTypes/'
          }
        },
        {
          "value": 'thesis',
          "type": 'genre',
          "uri": 'http://id.loc.gov/vocabulary/marcgt/the',
          "source": {
            "code": 'marcgt',
            "uri": 'http://id.loc.gov/vocabulary/marcgt/'
          }
        }
      ],
      "language": [
        {
          "value": 'English',
          "code": 'eng',
          "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
          "source": {
            "code": 'iso239-2b',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ],
      "note": [
        {
          "value": "My dissertation is a combination of three papers that I worked on at various stages of my doctoral studies at Stanford University Graduate School of Business. The central of theme of these papers is dynamic optimality with adjustment costs and gradualness in various economic environments. In all of these papers, I shared various tasks and responsibilities of the research with my coauthors. In Chapter 1, together with Ryota Iijima, I study a model of gradual adjustment in games, in which players can flexibly adjust and monitor their positions up until a deadline. Players' terminal and flow payoffs are influenced by their positions. I show that, unlike in one-shot games, the equilibrium is unique for a broad class of terminal payoffs when players' actions are flexible enough in the presence of (possibly small) noise. In a team-production model, the unique equilibrium selects an outcome that is approximately efficient when adjustment friction is small. I also examine the welfare implications of such gradualness in applications, including team production, hold-up problems, and dynamic contests. In Chapter 2, together with Christopher Hennessy and Ilya Streublaev, I study dynamic capital structure choice with a time-varying tax rate. Absent theoretical guidance, empiricists have been forced to rely upon numerical comparative statics from constant tax rate models in formulating testable implications of tradeoff theory in the context of natural experiments. I fill the theoretical void by solving in closed-form a dynamic tradeoff theoretic model in which corporate taxes follow a (two-state) Markov process with exogenous rate changes. I simulate ideal difference-in-differences estimations, finding that constant tax rate models offer poor guidance regarding testable implications. While constant rate models predict large symmetric responses to rate changes, my model with stochastic tax rates predicts small, asymmetric, and often statistically insignificant responses. Under plausible parameterizations with decade-long regimes, the true underlying theory -- that taxes matter -- is incorrectly rejected in about half of the simulated natural experiments. Moreover, tax response coefficients are actually smaller in simulated economies with larger tax-induced welfare losses. In Chapter 3, which is also joint work with Ryota Iijima, I consider a class of games in which players commonly observe noisy shocks and gradually adjust their actions without observing information about their opponents' behavior. Under a form of richness of the noise process, I prove equilibrium uniqueness when players' adjustment is flexible enough. In the case of potential games, the unique equilibrium approximates the global maximizer of the potential as the friction vanishes.",
          "type": 'summary'
        },
        {
          "value": 'Submitted to the Graduate School of Business.'
        },
        {
          "type": 'thesis',
          "structuredValue": [
            {
              "value": 'Thesis',
              "type": 'note'
            },
            {
              "value": 'Ph.D.',
              "type": 'degree'
            },
            {
              "value": 'Stanford University',
              "type": 'university'
            },
            {
              "value": '2017',
              "type": 'date'
            }
          ]
        },
        {
          "value": 'Akitada Kasahara, Jr.',
          "type": 'statement of responsibility',
          "standard": ['RDA']
        }
      ],
      "identifier": [
        {
          "value": '0000005406',
          "type": 'ETD ID'
        }
      ],
      "purl": 'http://purl.stanford.edu/hj456dt5655',
      "url": [
        {
          "value": 'https://etd.stanford.edu/view/0000005406',
          "type": 'ETD'
        }
      ],
      "marcEncodedData": [
        {
          "value": '     nam a       3i',
          "type": 'leader'
        },
        {
          "value": 'dorhj456dt5655',
          "type": '001'
        },
        {
          "value": 'm        d',
          "type": '006'
        },
        {
          "value": 'cr un',
          "type": '007'
        },
        {
          "value": '170607t20172017cau     om    000 0 eng d',
          "type": '008'
        }
      ],
      "adminMetadata": {
        "event": [
          {
            "type": 'creation',
            "date": [
              {
                "value": '2017-06-15',
                "encoding": ['w3cdtf']
              }
            ]
          },
          {
            "type": 'last modification',
            "date": [
              {
                "value": '2017-06-15',
                "encoding": ['w3cdtf']
              }
            ]
          }
        ],
        "contributor": [
          {
            "name": [
              {
                "value": 'ETD application'
              }
            ],
            "role": [
              {
                "value": 'data source'
              }
            ]
          },
          {
            "name": [
              {
                "code": 'CSt',
                "uri": 'http://id.loc.gov/vocabulary/organizations/cst',
                "source": {
                  "code": 'marcorg',
                  "uri": 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          },
          {
            "name": [
              {
                "code": 'CSt',
                "uri": 'http://id.loc.gov/vocabulary/organizations/cst',
                "source": {
                  "code": 'marcorg',
                  "uri": 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            "role": [
              {
                "value": 'transcribing agency'
              }
            ]
          }
        ],
        "language": [
          {
            "value": 'English',
            "code": 'eng',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
            "source": {
              "code": 'iso239-2b',
              "uri": 'http://id.loc.gov/vocabulary/iso639-2'
            }
          }
        ]
      }
    }
  end
  # rubocop:enable Metrics/LineLength

  let(:tz) { Time.zone }

  before do
    allow(Time).to receive(:zone).and_return(tz)
    allow(tz).to receive(:today).and_return(Date.parse('2017-06-15'))
  end

  it 'validates' do
    expect { Cocina::Models::Description.new(description) }.not_to raise_error
  end

  it 'builds' do
    expect(expected).to eq(description)
  end
end
