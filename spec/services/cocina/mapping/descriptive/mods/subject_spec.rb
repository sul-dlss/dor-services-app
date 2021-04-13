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
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  },
                  uri: 'http://id.loc.gov/authorities/subjects/sh2002012475',
                  value: '19th century',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'With only LCSH authorityURI on subject element' do
    # Example from fx157yc1405
    # Add authority based on authorityURI
    xit 'unimplemented spec' do
      let(:mods) do
        <<~XML
          <subject authorityURI="http://id.loc.gov/authorities/subjects">
            <geographic authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85001531">Africa</geographic>
            <temporal authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh2002012476">20th century</temporal>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85001531">Africa</geographic>
            <temporal authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh2002012476">20th century</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Africa',
                  type: 'place',
                  uri: 'http://id.loc.gov/authorities/subjects/sh85001531',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects'
                  }
                },
                {
                  value: '20th century',
                  type: 'time',
                  uri: 'http://id.loc.gov/authorities/subjects/sh85001531',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'With language attributes on subject element' do
    # Example from bc770gm9177
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85136516" lang="eng" script="Latn">
            <topic>Labor union</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh" lang="eng" script="Latn">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85136516">Labor union</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Labor union',
              type: 'topic',
              uri: 'http://id.loc.gov/authorities/subjects/sh85136516',
              source: {
                uri: 'http://id.loc.gov/authorities/subjects/',
                code: 'lcsh'
              },
              valueLanguage: {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                },
                valueScript: {
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              }
            }
          ]
        }
      end
    end
  end

  describe 'With language attributes on single subelement' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic lang="eng" script="Latn">Labor unions</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject lang="eng" script="Latn">
            <topic>Labor unions</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Labor unions',
              type: 'topic',
              valueLanguage: {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                },
                valueScript: {
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              }
            }
          ]
        }
      end
    end
  end

  describe 'With same language attributes on multiple subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic lang="eng" script="Latn">Labor unions</topic>
            <geographic lang="eng" script="Latn">United Kingdom</geographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject lang="eng" script="Latn">
            <topic>Labor unions</topic>
            <geographic>United Kingdom</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Labor unions',
                  type: 'topic'
                },
                {
                  value: 'United Kingdom',
                  type: 'place'
                }
              ],
              valueLanguage: {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                },
                valueScript: {
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              }
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'With multiple primary' do
    it_behaves_like 'MODS cocina mapping' do
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
        # Drop all instances of usage="primary" after first one
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

      let(:warnings) do
        [
          Notification.new(msg: 'Multiple marked as primary', context: { type: 'subject' })
        ]
      end
    end
  end

  describe 'Authority-only subject' do
    # Adapted from nv251kt0037
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="geonames" authorityURI="http://sws.geonames.org" valueURI="http://sws.geonames.org/2946447/">
            <geographic/>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="geonames" authorityURI="http://sws.geonames.org" valueURI="http://sws.geonames.org/2946447/" />
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              source: {
                code: 'geonames',
                uri: 'http://sws.geonames.org'
              },
              uri: 'http://sws.geonames.org/2946447/'
            }
          ]
        }
      end
    end
  end

  describe 'Parallel subjects' do
    # Adapted from bc269jd4815
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject altRepGroup="1" authority="lcsh">
            <titleInfo>
              <title>Chu ci (Ancient Chinese poems)</title>
            </titleInfo>
          </subject>
          <subject altRepGroup="1">
            <titleInfo>
              <title>&#x695A;&#x8F9E;(Ancient Chinese poems)</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              parallelValue: [
                {
                  source: {
                    code: 'lcsh'
                  },
                  value: 'Chu ci (Ancient Chinese poems)'

                },
                {
                  value: '楚辞(Ancient Chinese poems)'
                }
              ],
              type: 'title'
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject xlink:href="http://subject.org/subject" />
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              valueAt: 'http://subject.org/subject'
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'Element with xlink should not have value' do
    # Adapted from vj685ps3229
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject xmlns:xlink="http://www.w3.org/1999/xlink" authority="fast" xlink:href="http://id.worldcat.org/fast/1355886">
            <temporal>1939-1945</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: '1939-1945',
              type: 'time',
              source: {
                code: 'fast'
              },
              valueAt: 'http://id.worldcat.org/fast/1355886'
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'Element with both xlink and value')] }
    end
  end
end
