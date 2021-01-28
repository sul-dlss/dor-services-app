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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Virago</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'publication',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Virago'
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
        }
      end
    end
  end

  describe 'Publisher - transliterated' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables">Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables">
            <publisher>Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'publication',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Institut russkoĭ literatury (Pushkinskiĭ Dom)',
                      "type": 'transliteration',
                      "standard": {
                        "value": 'ALA-LC Romanization Tables'
                      },
                      "valueLanguage": {
                        "code": 'rus',
                        "source": {
                          "code": 'iso639-2b'
                        },
                        "valueScript": {
                          "code": 'Latn',
                          "source": {
                            "code": 'iso15924'
                          }
                        }
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

  describe 'Publisher - other language' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher lang="rus" script="Cyrl">СФУ</publisher>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication" lang="rus" script="Cyrl">
            <publisher>СФУ</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'publication',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'СФУ',
                      "valueLanguage": {
                        "code": 'rus',
                        "source": {
                          "code": 'iso639-2b'
                        },
                        "valueScript": {
                          "code": 'Cyrl',
                          "source": {
                            "code": 'iso15924'
                          }
                        }
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

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <publisher>Ardis</publisher>
            <publisher>Commonplace Books</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'publication',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Ardis'
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
                },
                {
                  "name": [
                    {
                      "value": 'Commonplace Books'
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
          "event": [
            {
              "type": 'production',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Stanford University'
                    }
                  ],
                  "type": 'organization',
                  "role": [
                    {
                      "value": 'issuing body',
                      "code": 'isb',
                      "uri": 'http://id.loc.gov/vocabulary/relators/isb',
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
                  "value": '2020'
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
          "event": [
            {
              "type": 'distribution',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Stanford University'
                    }
                  ],
                  "type": 'organization',
                  "role": [
                    {
                      "value": 'distributor',
                      "code": 'dst',
                      "uri": 'http://id.loc.gov/vocabulary/relators/dst',
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
                  "value": '2020'
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
            <dateOther type="distribution">2020</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'manufacture',
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Stanford University'
                    }
                  ],
                  "type": 'organization',
                  "role": [
                    {
                      "value": 'manufacturer',
                      "code": 'mfr',
                      "uri": 'http://id.loc.gov/vocabulary/relators/mfr',
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
                  "value": '2020'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Publisher with dateOther type' do
    # Adapted from druid:sz423cd8263
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="producer">
            <place>
              <placeTerm>Stanford, Calif.</placeTerm>
            </place>
            <publisher>Stanford University, Department of Biostatistics</publisher>
            <dateOther type="production">2002</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo displayLabel="producer" eventType="production">
            <place>
              <placeTerm type="text">Stanford, Calif.</placeTerm>
            </place>
            <publisher>Stanford University, Department of Biostatistics</publisher>
            <dateOther type="production">2002</dateOther>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          "event": [
            {
              "type": 'production',
              "displayLabel": 'producer',
              "location": [
                {
                  "value": 'Stanford, Calif.'
                }
              ],
              "contributor": [
                {
                  "name": [
                    {
                      "value": 'Stanford University, Department of Biostatistics'
                    }
                  ],
                  "type": 'organization',
                  "role": [
                    {
                      "value": 'issuing body',
                      "code": 'isb',
                      "uri": 'http://id.loc.gov/vocabulary/relators/isb',
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
                  "value": '2002'
                }
              ]
            }
          ]
        }
      end
    end
  end
end
