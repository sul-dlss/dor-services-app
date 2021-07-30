# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for event (h2 specific)' do
  describe 'Publication date: 2021-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="edtf">2021-01-01</dateIssued>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf">2021-01-01</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, Creation date: 2020-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            },
            {
              type: 'creation',
              date: [
                {
                  value: '2020-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued encoding="edtf">2021-01-01</dateIssued>
          </originInfo>
          <originInfo eventType="creation">
            <dateCreated encoding="edtf">2020-01-01</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date range: 2020-01-01 to 2021-01-01' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '2020-01-01',
                      type: 'start'
                    },
                    {
                      value: '2021-01-01',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf" point="start">2020-01-01</dateCreated>
            <dateCreated encoding="edtf" point="end">2021-01-01</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate single creation date: approx. 1900' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '1900',
                  type: 'creation',
                  qualifier: 'approximate',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf" qualifier="approximate">1900</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date range with approximate start date: approx. 1900-1910' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start',
                      qualifier: 'approximate'
                    },
                    {
                      value: '1910',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf" point="start" qualifier="approximate">1900</dateCreated>
            <dateCreated encoding="edtf" point="end">1910</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date range with approximate end date: 1900-approx. 1910' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start'
                    },
                    {
                      value: '1910',
                      type: 'end',
                      qualifier: 'approximate'
                    }
                  ],
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf" point="start">1900</dateCreated>
            <dateCreated encoding="edtf" point="end" qualifier="approximate">1910</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Approximate creation date range: approx. 1900-approx. 1910' do
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  structuredValue: [
                    {
                      value: '1900',
                      type: 'start'
                    },
                    {
                      value: '1910',
                      type: 'end'
                    }
                  ],
                  type: 'creation',
                  qualifier: 'approximate',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo eventType="creation">
            <dateCreated encoding="edtf" point="start" qualifier="approximate">1900</dateCreated>
            <dateCreated encoding="edtf" point="end" qualifier="approximate">1910</dateCreated>
          </originInfo>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, Uncited publisher: Stanford University Press' do
    # Uncited publisher appears in event only
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'creation',
              date: [
                {
                  value: '2021-01-01',
                  type: 'creation',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ]
            },
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
          <originInfo eventType="creation">
            <dateCreated encoding="edtf">2021-01-01</dateCreated>
          </originInfo>
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, Uncited publisher: Stanford University Press' do
    # Uncited publisher appears in event only
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ],
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
            <dateIssued encoding="edtf">2021-01-01</dateIssued>
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, Cited publisher: Stanford University Press' do
    # Cited publisher appears in contributor and event
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
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
          ],
          event: [
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'edtf'
                  }
                }
              ],
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
          <name type="corporate">
            <namePart>Stanford University Press</namePart>
            <role>
              <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/pbl" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" type="text">publisher</roleTerm>
              <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/pbl" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" type="code">pbl</roleTerm>
            </role>
          </name>
          <originInfo eventType="publication">
            <dateIssued encoding="edtf">2021-01-01</dateIssued>
            <publisher>Stanford University Press</publisher>
          </originInfo>
        XML
      end
    end
  end
end
