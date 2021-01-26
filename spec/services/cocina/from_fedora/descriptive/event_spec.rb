# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Event do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

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

  context 'with a simple dateCreated with a trailing period' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated>1980.</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1980'
            }
          ]
        }
      ]
    end
  end

  context 'with a single dateOther' do
    describe 'with type attribute on the dateOther element' do
      let(:xml) do
        <<~XML
          <originInfo>
            <dateOther type="Islamic">1441 AH</dateOther>
          </originInfo>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "date": [
              {
                "value": '1441 AH',
                "note": [
                  {
                    "value": 'Islamic',
                    "type": 'date type'
                  }
                ]
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('originInfo/dateOther missing eventType')
      end
    end

    describe 'with eventType attribute at the originInfo level' do
      let(:xml) do
        <<~XML
          <originInfo eventType="acquisition" displayLabel="Acquisition date">
            <dateOther encoding="w3cdtf">1992</dateOther>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "type": 'acquisition',
            "displayLabel": 'Acquisition date',
            "date": [
              {
                "value": '1992',
                "encoding": {
                  "code": 'w3cdtf'
                }
              }
            ]
          }
        ]
      end
    end

    describe 'with eventType="production" dateOther type="Julian" (MODS 3.6 and before)' do
      let(:xml) do
        <<~XML
          <originInfo eventType="production">
            <dateOther type="Julian">1544-02-02</dateOther>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "type": 'creation',
            "date": [
              {
                "value": '1544-02-02',
                "note": [
                  {
                    "value": 'Julian',
                    "type": 'date type'
                  }
                ]
              }
            ]
          }
        ]
      end
    end

    describe 'with eventType="production" dateCreated calendar="Julian" (MODS 3.7)' do
      let(:xml) do
        <<~XML
          <originInfo eventType="production">
            <dateCreated calendar="Julian">1544-02-02</dateCreated>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "type": 'creation',
            "date": [
              {
                "value": '1544-02-02',
                "note": [
                  {
                    "value": 'Julian',
                    "type": 'calendar'
                  }
                ]
              }
            ]
          }
        ]
      end
    end

    describe 'without any type attribute, with displayLabel' do
      let(:xml) do
        <<~XML
          <originInfo displayLabel="Acquisition date">
            <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
          </originInfo>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "displayLabel": 'Acquisition date',
            "date": [
              {
                "value": '1970-11-23',
                "encoding": {
                  "code": 'w3cdtf'
                },
                "status": 'primary'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn)
          .with('originInfo/dateOther missing eventType')
      end
    end
  end

  context 'with issuance for a creation event' do
    let(:xml) do
      <<~XML
        <originInfo eventType="production">
          <dateCreated encoding="w3cdtf" keyDate="yes">1988-08-03</dateCreated>
          <issuance>monographic</issuance>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1988-08-03',
              "status": 'primary',
              "encoding": {
                "code": 'w3cdtf'
              }
            }
          ],
          "note": [
            {
              "value": 'monographic',
              "type": 'issuance',
              "source": {
                "value": 'MODS issuance terms'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with example adapted from hn285fy7937 after normalization' do
    let(:xml) do
      <<~XML
        <originInfo altRepGroup="1" eventType="publication">
          <place>
            <placeTerm type="code" authority="marccountry">cc</placeTerm>
          </place>
          <place>
            <placeTerm type="text">Chengdu</placeTerm>
          </place>
          <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
          <dateIssued>2005</dateIssued>
          <edition>Di 1 ban.</edition>
          <issuance>monographic</issuance>
        </originInfo>
        <originInfo altRepGroup="1" eventType="publication">
          <place>
            <placeTerm type="code" authority="marccountry">cc</placeTerm>
          </place>
          <place>
            <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
          </place>
          <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
          <dateIssued>2005</dateIssued>
          <edition>[Di 1 ban in Chinese]</edition>
          <issuance>monographic</issuance>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "location": [
            {
              "parallelValue": [
                {
                  "value": 'Chengdu'
                },
                {
                  "value": '[Chengdu in Chinese]'
                }
              ]
            },
            {
              "code": 'cc',
              "source": {
                "code": 'marccountry'
              }
            }
          ],
          "contributor": [
            {
              "type": 'organization',
              "name": [
                {
                  "parallelValue": [
                    {
                      "value": 'Sichuan chu ban ji tuan, Sichuan wen yi chu ban she'
                    },
                    {
                      "value": '[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]'
                    }
                  ]
                }
              ],
              "role": [
                {
                  "value": 'publisher',
                  "code": 'pbl',
                  "uri": 'http://id.loc.gov/vocabulary/relators/pbl',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ],
          "date": [
            {
              "value": '2005'
            }
          ],
          "note": [
            {
              "type": 'edition',
              "parallelValue": [
                {
                  "value": 'Di 1 ban.'
                },
                {
                  "value": '[Di 1 ban in Chinese]'
                }
              ]
            },
            {
              "type": 'issuance',
              "value": 'monographic',
              "source": {
                "value": 'MODS issuance terms'
              }

            }

          ]
        }
      ]
    end
  end

  context 'with example adapted from bh212vz9239 in different order' do
    # This places the originInfo with additional elements in the second position.
    let(:xml) do
      <<~XML
        <originInfo altRepGroup="02">
          <place>
            <placeTerm type="text">Guangdong in Chinese</placeTerm>
          </place>
          <publisher>Guangdong lu jun ce liang ju in Chinese</publisher>
          <dateIssued>Minguo 11-18 [1922-1929] in Chinese</dateIssued>
        </originInfo>
        <originInfo altRepGroup="02">
          <place>
            <placeTerm type="code" authority="marccountry">cc</placeTerm>
          </place>
          <place>
            <placeTerm type="text">Guangdong</placeTerm>
          </place>
          <publisher>Guangdong lu jun ce liang ju</publisher>
          <dateIssued>Minguo 11-18 [1922-1929]</dateIssued>
          <dateIssued encoding="marc" point="start">1922</dateIssued>
          <dateIssued encoding="marc" point="end">1929</dateIssued>
          <issuance>monographic</issuance>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "location": [
            {
              "parallelValue": [
                {
                  "value": 'Guangdong in Chinese'
                },
                {
                  "value": 'Guangdong'
                }
              ]
            },
            {
              "code": 'cc',
              "source": {
                "code": 'marccountry'
              }
            }
          ],
          "contributor": [
            {
              "type": 'organization',
              "name": [
                {
                  "parallelValue": [
                    {
                      "value": 'Guangdong lu jun ce liang ju in Chinese'
                    },
                    {
                      "value": 'Guangdong lu jun ce liang ju'
                    }
                  ]
                }
              ],
              "role": [
                {
                  "value": 'publisher',
                  "code": 'pbl',
                  "uri": 'http://id.loc.gov/vocabulary/relators/pbl',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ],
          "date": [
            {
              "parallelValue": [
                {
                  "value": 'Minguo 11-18 [1922-1929] in Chinese'
                },
                {
                  "value": 'Minguo 11-18 [1922-1929]'
                }
              ]
            },
            {
              "structuredValue": [
                {
                  "value": '1922',
                  "type": 'start',
                  "encoding": {
                    "code": 'marc'
                  }
                },
                {
                  "value": '1929',
                  "type": 'end',
                  "encoding": {
                    "code": 'marc'
                  }
                }
              ]
            }
          ],
          "note": [
            {
              "type": 'issuance',
              "value": 'monographic',
              "source": {
                "value": 'MODS issuance terms'
              }
            }
          ]
        }
      ]
    end
  end

  # From druid:mm706hr7414
  context 'with an originInfo that does not get an event type' do
    # This places the originInfo with additional elements in the second position.
    let(:xml) do
      <<~XML
          <originInfo altRepGroup="02">
            <place>
              <placeTerm type="code" authority="marccountry">is</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Tel-Aviv</placeTerm>
            </place>
            <publisher>A. Sh&#x1E6D;ibel</publisher>
            <dateIssued>1939</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo script="" altRepGroup="02">
            <place>
              <placeTerm type="text">&#x5EA;&#x5DC;&#x5BE;&#x5D0;&#x5D1;&#x5D9;&#x5D1; :</placeTerm>
            </place>
            <publisher>&#x5E9;. &#x5E9;&#x5D8;&#x5D9;&#x5D1;&#x5DC;,1939.</publisher>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1939'
            }
          ],
          "location": [
            {
              "parallelValue": [
                {
                  "value": 'Tel-Aviv'
                },
                {
                  "value": 'תל־אביב :'
                }
              ]
            },
            {
              "source": {
                "code": 'marccountry'
              },
              "code": 'is'
            }
          ],
          "note": [
            {
              "source": {
                "value": 'MODS issuance terms'
              },
              "type": 'issuance',
              "value": 'monographic'
            }
          ],
          "contributor": [
            {
              "name": [
                {
                  "parallelValue": [
                    {
                      "value": 'A. Shṭibel'
                    },
                    {
                      "value": 'ש. שטיבל,1939.'
                    }
                  ]
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
                }
              ]
            }
          ]
        }
      ]
    end
  end

  # From druid:bs861pk7886
  context 'with an originInfo that has place and publisher, but no date' do
    # This places the originInfo with additional elements in the second position.
    let(:xml) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
          </place>
          <publisher>Stanford University. Department of Geophysics</publisher>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "contributor": [
            {
              "name": [
                {
                  "value": 'Stanford University. Department of Geophysics'
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
                }
              ]
            }
          ],
          "location": [
            {
              "uri": 'http://id.loc.gov/authorities/names/n50046557',
              "source": {
                "code": 'marccountry',
                "uri": 'http://id.loc.gov/authorities/names/'
              },
              "value": 'Stanford (Calif.)'
            }
          ]
        }
      ]
    end
  end

  # From druid:ht706sj6651
  context 'with an originInfo that is a presentation' do
    let(:xml) do
      <<~XML
        <originInfo displayLabel="Presented" eventType="presentation">
          <place>
            <placeTerm type="text" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
          </place>
          <publisher>Stanford Institute for Theoretical Economics</publisher>
          <dateIssued keyDate="yes" encoding="w3cdtf">2018</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          "type": 'presentation',
          "date": [
            {
              "value": '2018',
              "encoding": {
                "code": 'w3cdtf'
              },
              "status": 'primary'
            }
          ],
          "displayLabel": 'Presented',
          "contributor": [
            {
              "name": [
                {
                  "value": 'Stanford Institute for Theoretical Economics'
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
                }
              ]
            }
          ],
          "location": [
            {
              "uri": 'http://id.loc.gov/authorities/names/n50046557',
              "value": 'Stanford (Calif.)'
            }
          ]
        }
      ]
    end
  end
end
