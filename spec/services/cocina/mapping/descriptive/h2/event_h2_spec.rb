# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for event (h2 specific)' do
  # Embargo year pulled from cocina access stanza
  let(:embargo) do
    {
      access: {
        embargo: {
          releaseDate: '2023-01-01T00:00:00.000+00:00'
        }
      }
    }
  end

  describe 'Publication date: 2021-01-01, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, current year: 2022, embargo year: 2023' do
    # cocina includes :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2023</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, Creation date: 2020-01-01, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date range: 2020-01-01 to 2021-01-01, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Approximate single creation date: approx. 1900, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date range with approximate start date: approx. 1900-1910, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date range with approximate end date: 1900-approx. 1910, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Approximate creation date range: approx. 1900-approx. 1910, current year: 2022' do
    # cocina does not include :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, current year: 2022, embargo year: 2023' do
    # cocina includes :embargo
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2023</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01, current year: 2022, uncited publisher: Stanford University Press' do
    # cocina does not include :embargo
    # uncited publisher appears in event only
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, current year: 2022, uncited publisher: Stanford University Press' do
    # cocina does not include :embargo
    # uncited publisher appears in event only
    xit 'not implemented' do
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
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end

  describe 'Publication date: 2021-01-01, current year: 2022, cited publisher: Stanford University Press' do
    # cocina does not include :embargo
    # cited publisher appears in contributor and event
    xit 'not implemented' do
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
                },
                {
                  value: 'Creator',
                  type: 'DataCite role'
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
          <extension displayLabel="datacite">
            <creators>
              <creator>
                <creatorName nameType="Organizational">Stanford University Press</creatorName>
              </creator>
            </creators>
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end
    end
  end
end
