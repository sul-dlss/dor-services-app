# frozen_string_literal: true

require 'rails_helper'
require 'support/mods_mapping_spec_helper'

# numbered example comments refer to
# from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt
RSpec.describe Cocina::ToFedora::Descriptive::Event do
  # see spec/support/mods_mapping_spec_helper.rb for how writer is used in shared examples
  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods(mods_attributes) do
        described_class.write(xml: xml, events: events, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when events is nil' do
    let(:events) { nil }

    it_behaves_like 'cocina to MODS', '' # empty mods
  end

  context 'when it has a single dateOther' do
    describe 'with eventType="acquisition"' do
      let(:events) do
        [
          Cocina::Models::Event.new(
            {
              type: 'acquisition',
              date: [
                {
                  value: '1970-11-23',
                  status: 'primary',
                  encoding:
                          {
                            code: 'w3cdtf'
                          }
                }
              ]
            }
          )
        ]
      end

      it_behaves_like 'cocina to MODS', <<~XML
        <originInfo eventType="acquisition">
          <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
        </originInfo>
      XML
    end

    describe 'without note, with displayLabel' do
      let(:events) do
        [
          Cocina::Models::Event.new(
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
          )
        ]
      end

      it_behaves_like 'cocina to MODS', <<~XML
        <originInfo displayLabel="Acquisition date">
          <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
        </originInfo>
      XML
    end
  end

  context 'when eventType matches date type "distribution"' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'distribution',
            date: [
              {
                value: ''
              }
            ],
            contributor: [
              {
                name: [
                  {
                    value: 'For sale by the Superintendent of Documents, U.S. Government Publishing Office'
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'publisher',
                    code: 'pbl',
                    uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                    source: {
                      code: 'marcrelator',
                      uri: 'http://id.loc.gov/vocabulary/relators/'
                    }
                  }
                ]
              }
            ],
            location: [
              {
                value: 'Washington, DC'
              }
            ]
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo eventType="distribution">
        <place>
          <placeTerm type="text">Washington, DC</placeTerm>
        </place>
        <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
        <dateOther/>
      </originInfo>
    XML
  end

  context 'when it has a publisher that is not marcrelator' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          type: 'publication',
          contributor: [
            {
              name: [{ value: 'Stanford University Press' }],
              type: 'organization',
              role: [
                {
                  value: 'Publisher',
                  source: { value: 'Stanford self-deposit contributor types' }
                }
              ]
            }
          ]
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo eventType="publication">
        <publisher>Stanford University Press</publisher>
      </originInfo>
    XML
  end

  context 'with multiple events and missing event type' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "type": 'creation',
          "date": [
            {
              "value": '1899'
            }
          ],
          "location": [
            {
              "value": 'York'
            }
          ]
        ),
        Cocina::Models::Event.new(
          "date": [
            {
              "value": '1901'
            }
          ],
          "location": [
            {
              "value": 'London'
            }
          ]
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo eventType="production">
        <dateCreated>1899</dateCreated>
        <place>
          <placeTerm type="text">York</placeTerm>
        </place>
      </originInfo>
      <originInfo>
        <dateOther>1901</dateOther>
        <place>
          <placeTerm type="text">London</placeTerm>
        </place>
      </originInfo>
    XML
  end

  context 'when event location missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "code": 'xxu'
            }
          ]
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo>
        <place>
          <placeTerm type="code">xxu</placeTerm>
        </place>
      </originInfo>
    XML
  end

  context 'when event location with code missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "code": 'cau',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau'
            }
          ]
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo>
        <place>
          <placeTerm type="code" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
        </place>
      </originInfo>
    XML
  end

  context 'when event location with value missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "value": 'California',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau'
            }
          ]
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo>
        <place>
          <placeTerm type="text" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
        </place>
      </originInfo>
    XML
  end

  # From druid:bm971cx9348
  context 'with originInfo with dateIssued with single point' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            "type": 'publication',
            "date": [
              {
                "value": '[192-?]-[193-?]'
              },
              {
                "value": '1920',
                "encoding": {
                  "code": 'marc'
                },
                "type": 'start'
              }
            ],
            "note": [
              {
                "type": 'edition',
                "value": '2nd ed.'
              },
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
                    "value": 'H.M. Stationery Off'
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
                "value": 'London'
              },
              {
                "source": {
                  "code": 'marccountry'
                },
                "code": 'enk'
              }
            ]
          }
        )
      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo eventType="publication">
        <dateIssued>[192-?]-[193-?]</dateIssued>
        <dateIssued encoding="marc" point="start">1920</dateIssued>
        <place>
          <placeTerm type="text">London</placeTerm>
        </place>
        <place>
          <placeTerm type="code" authority="marccountry">enk</placeTerm>
        </place>
        <publisher>H.M. Stationery Off</publisher>
        <edition>2nd ed.</edition>
        <issuance>monographic</issuance>
      </originInfo>
    XML
  end

  # From druid:ht706sj6651
  context 'with presentation' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )

      ]
    end

    it_behaves_like 'cocina to MODS', <<~XML
      <originInfo displayLabel="Presented" eventType="presentation">
        <place>
          <placeTerm type="text" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
        </place>
        <publisher>Stanford Institute for Theoretical Economics</publisher>
        <dateIssued keyDate="yes" encoding="w3cdtf">2018</dateIssued>
      </originInfo>
    XML
  end
end
