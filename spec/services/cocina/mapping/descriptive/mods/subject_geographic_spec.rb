# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject geographic <--> cocina mappings' do
  describe 'Geographic subject subdivision' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic>Cats</topic>
            <geographic>Europe</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Europe',
                  type: 'place'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Hierarchical geographic subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <hierarchicalGeographic>
              <continent>North America</continent>
              <country>Canada</country>
              <city>Vancouver</city>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'North America',
                  type: 'continent'
                },
                {
                  value: 'Canada',
                  type: 'country'
                },
                {
                  value: 'Vancouver',
                  type: 'city'
                }
              ],
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Hierarchical geographic subject with authority on subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <hierarchicalGeographic>
              <continent>North America</continent>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'North America',
                  type: 'continent'
                }
              ],
              type: 'place',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Hierarchical geographic subject with authority on hierarchicalGeographic' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <hierarchicalGeographic authority="lcsh">
              <continent>North America</continent>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <hierarchicalGeographic>
              <continent>North America</continent>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'North America',
                  type: 'continent'
                }
              ],
              type: 'place',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Hierarchical geographic subject with mapped types' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <hierarchicalGeographic>
              <extraterrestrialArea>Moon</extraterrestrialArea>
              <citySection>Moon Zero Two</citySection>
            </hierarchicalGeographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Moon',
                  type: 'extraterrestrial area'
                },
                {
                  value: 'Moon Zero Two',
                  type: 'city section'
                }
              ],
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic code subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="marcgac">
            <geographicCode>n-us-md</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              code: 'n-us-md',
              type: 'place',
              source: {
                code: 'marcgac'
              }
            }
          ]
        }
      end
    end
  end

  describe 'marc geographic area code subject with trailing dashes' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographicCode authority="marcgac">n-us---</geographicCode>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="marcgac">
            <geographicCode>n-us</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              code: 'n-us',
              type: 'place',
              source: {
                code: 'marcgac'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Geographic code and term' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographic authority="lcsh">United States</geographic>
            <geographicCode authority="iso3166">us</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              parallelValue: [
                {
                  value: 'United States',
                  source: {
                    code: 'lcsh'
                  }
                },
                {
                  code: 'us',
                  source: {
                    code: 'iso3166'
                  }
                }
              ],
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">
            <geographic>Antarctica</geographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <subject authority="lcsh">
            <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">Antarctica</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Antarctica',
              uri: 'http://id.loc.gov/authorities/subjects/sh85005490',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              },
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject with authority on subject element' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="marcgac">
            <geographic>Africa</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Africa',
              type: 'place',
              source: {
                code: 'marcgac'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject with altRepGroup - A' do
    # Adapted from hv324dj9498
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject altRepGroup="1" authority="lcsh">
            <geographic>Mália Site (Greece)</geographic>
            <topic>Antiquities</topic>
          </subject>
          <subject altRepGroup="1">
            <geographic>Μαλιά (Ελλάδα)</geographic>
            <topic>Αρχαιότητες</topic>
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
                  structuredValue: [
                    {
                      value: 'Mália Site (Greece)',
                      type: 'place'
                    },
                    {
                      value: 'Antiquities',
                      type: 'topic'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Μαλιά (Ελλάδα)',
                      type: 'place'
                    },
                    {
                      value: 'Αρχαιότητες',
                      type: 'topic'
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

  describe 'Geographic subject with altRepGroup - B' do
    # Adapted from hv324dj9498
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject altRepGroup="1" authority="lcsh">
            <geographic>Ḳiryat Ḥayim (Haifa, Israel)</geographic>
          </subject>
          <subject altRepGroup="1" authority="lcsh">
            <geographic>Ḳiryat Ḥayim (Haifa, Israel) in Hebrew</geographic>
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
                  value: 'Ḳiryat Ḥayim (Haifa, Israel)'
                },
                {
                  source: {
                    code: 'lcsh'
                  },
                  value: 'Ḳiryat Ḥayim (Haifa, Israel) in Hebrew'
                }
              ],
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Geographic subject with language' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <geographic lang="eng" valueURI="http://sws.geonames.org/2960860/" authority="geonames" authorityURI="http://www.geonames.org/ontology#">Arctic Ocean</geographic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <subject authority="geonames" lang="eng">
            <geographic authority="geonames" authorityURI="http://www.geonames.org/ontology#" valueURI="http://sws.geonames.org/2960860/">Arctic Ocean</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Arctic Ocean',
              valueLanguage: {
                code: 'eng',
                source: {
                  code: 'iso639-2b'
                }
              },
              uri: 'http://sws.geonames.org/2960860/',
              source: {
                code: 'geonames',
                uri: 'http://www.geonames.org/ontology#'
              },
              type: 'place'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple geographic codes' do
    # Adapted from druid:zz236hg5740
    xit 'updated spec not implemented: multiple geographic codes' do
      let(:mods) do
        <<~XML
          <subject>
            <geographicCode authority="marcgac">n-us-tx</geographicCode>
            <geographicCode authority="marcgac">n-us-ca</geographicCode>
            <geographicCode authority="marcgac">n-us-or</geographicCode>
            <geographicCode authority="marcgac">n-us-nm</geographicCode>
            <geographicCode authority="marcgac">n-us-ut</geographicCode>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="marcgac">
            <geographicCode>n-us-tx</geographicCode>
          </subject>
          <subject authority="marcgac">
            <geographicCode>n-us-ca</geographicCode>
          </subject>
          <subject authority="marcgac">
            <geographicCode>n-us-or</geographicCode>
          </subject>
          <subject authority="marcgac">
            <geographicCode>n-us-nm</geographicCode>
          </subject>
          <subject authority="marcgac">
            <geographicCode>n-us-ut</geographicCode>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              source: {
                code: 'marcgac'
              },
              code: 'n-us-tx',
              type: 'place'
            },
            {
              source: {
                code: 'marcgac'
              },
              code: 'n-us-ca',
              type: 'place'
            },
            {
              source: {
                code: 'marcgac'
              },
              code: 'n-us-or',
              type: 'place'
            },
            {
              source: {
                code: 'marcgac'
              },
              code: 'n-us-nm',
              type: 'place'
            },
            {
              source: {
                code: 'marcgac'
              },
              code: 'n-us-ut',
              type: 'place'
            }
          ]
        }
      end
    end
  end
end
