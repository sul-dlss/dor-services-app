# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo publisher <--> cocina mappings' do
  describe 'Publisher' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher>Virago</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Virago'
                    }
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher - transliterated' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher lang="rus" script="Latn"
              transliteration="ALA-LC Romanization Tables">Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Institut russkoĭ literatury (Pushkinskiĭ Dom)',
                      type: 'transliteration',
                      standard: {
                        value: 'ALA-LC Romanization Tables'
                      },
                      valueLanguage: {
                        code: 'rus',
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
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher - other language' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher lang="rus" script="Cyrl">СФУ</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'СФУ',
                      valueLanguage: {
                        code: 'rus',
                        source: {
                          code: 'iso639-2b'
                        },
                        valueScript: {
                          code: 'Cyrl',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    }
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multiple publishers' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher>Ardis</publisher>
            <publisher>Commonplace Books</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              contributor: [
                {
                  name: [
                    {
                      value: 'Ardis'
                    }
                  ],
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
                  ],
                  type: 'organization'
                },
                {
                  name: [
                    {
                      value: 'Commonplace Books'
                    }
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with eventType production' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production">
            <publisher>Stanford University</publisher>
            <dateOther type="production">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'creator',
                      code: 'cre',
                      uri: 'http://id.loc.gov/vocabulary/relators/cre',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'production'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with eventType distribution' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="distribution">
            <publisher>Stanford University</publisher>
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'distribution',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'distributor',
                      code: 'dst',
                      uri: 'http://id.loc.gov/vocabulary/relators/dst',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'distribution'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with eventType manufacture' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="manufacture">
            <publisher>Stanford University</publisher>
            <dateOther type="manufacture">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'manufacture',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'manufacturer',
                      code: 'mfr',
                      uri: 'http://id.loc.gov/vocabulary/relators/mfr',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'manufacture'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with displayLabel producer' do
    # Adapted from druid:sz423cd8263

    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction used displayLabel as a stopgap measure.
    # This test is for a displayLabel value that should be converted to eventType.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="producer">
            <place>
              <placeTerm>Stanford, Calif.</placeTerm>
            </place>
            <publisher>Stanford University</publisher>
            <dateOther type="production">2020</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="production">
            <place>
              <placeTerm type="text">Stanford, Calif.</placeTerm>
            </place>
            <publisher>Stanford University</publisher>
            <dateOther type="production">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              location: [
                {
                  value: 'Stanford, Calif.'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'creator',
                      code: 'cre',
                      uri: 'http://id.loc.gov/vocabulary/relators/cre',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'production'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with displayLabel distributor' do
    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction used displayLabel as a stopgap measure.
    # This test is for a displayLabel value that should be converted to eventType.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="distributor">
            <publisher>Stanford University</publisher>
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="distribution">
            <publisher>Stanford University</publisher>
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'distribution',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'distributor',
                      code: 'dst',
                      uri: 'http://id.loc.gov/vocabulary/relators/dst',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'distribution'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with displayLabel manufacturer' do
    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction used displayLabel as a stopgap measure.
    # This test is for a displayLabel value that should be converted to eventType.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="manufacturer">
            <publisher>Stanford University</publisher>
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="manufacture">
            <publisher>Stanford University</publisher>
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'manufacture',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
                  role: [
                    {
                      value: 'manufacturer',
                      code: 'mfr',
                      uri: 'http://id.loc.gov/vocabulary/relators/mfr',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ],
              date: [
                {
                  value: '2020',
                  type: 'distribution'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'publisher displayLabel' do
    # Arcadia says: because eventType is a relatively new addition to the MODS schema,
    #   records converted from MARC to MODS prior to its introduction used displayLabel as a stopgap measure.
    # This test is for a displayLabel value that should be converted to eventType.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="publisher">
            <publisher>Stanford University</publisher>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Stanford University</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University'
                    }
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # specs added by devs below

  context 'when publisher is not marcrelator and has no authority, authorityURI or valueURI' do
    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
                  role: [
                    {
                      value: 'Publisher',
                      source: { value: 'Stanford self-deposit contributor types' }
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      # marcrelator is added
      let(:roundtrip_cocina) do
        {
          event: [
            {
              type: 'publication',
              contributor: [
                {
                  name: [
                    {
                      value: 'Stanford University Press'
                    }
                  ],
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
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end
end
