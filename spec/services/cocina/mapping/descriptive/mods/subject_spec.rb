# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'Multi-term subject with authority for both set and terms and URIs for terms' do
    # Adapted from bv660dz6094
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85001531">Africa</geographic>
            <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh99001269">Maps</genre>
            <temporal authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh2002012475">19th century</temporal>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85001531">Africa</geographic>
            <genre authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99001269">Maps</genre>
            <temporal authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh2002012475">19th century</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  },
                  uri: 'http://id.loc.gov/authorities/subjects/sh85001531',
                  value: 'Africa',
                  type: 'place'
                },
                {
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  },
                  uri: 'http://id.loc.gov/authorities/subjects/sh99001269',
                  value: 'Maps',
                  type: 'genre'
                },
                {
                  "source": {
                    "code": 'lcsh',
                    "uri": 'http://id.loc.gov/authorities/subjects/'
                  },
                  "uri": 'http://id.loc.gov/authorities/subjects/sh2002012475',
                  "value": '19th century',
                  "type": 'time'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'With multiple primary' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <subject usage="primary">
          <topic>Trees</topic>
        </subject>
        <subject usage="primary">
          <topic>Birds</topic>
        </subject>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <subject usage="primary">
          <topic>Trees</topic>
        </subject>
        <subject>
          <topic>Birds</topic>
        </subject>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            value: 'Trees',
            type: 'topic',
            status: 'primary'
          },
          {
            value: 'Birds',
            type: 'topic'
          }
        ]
      }
    end

    let (:warnings) do
      [
        Notification.new(msg: 'Multiple subjects marked as primary')
      ]
    end
  end
end
