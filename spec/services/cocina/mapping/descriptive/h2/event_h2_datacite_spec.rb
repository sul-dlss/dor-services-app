# frozen_string_literal: true

require 'rails_helper'

# Use publication date if present
# If embargoed and no publication date provided, use embargo release date
# If neither available, cannot map to DataCite

RSpec.describe 'Cocina --> DataCite mappings for event (h2 specific)' do
  describe 'Publication date: 2021-01-01 OR No publication date or embargo, deposit finished 2021-01-01' do
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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <publicationYear>2021</publicationYear>
          <dates>
            <date dateType="Issued">2021-01-01</date>
          </dates>
        XML
      end
    end
  end

  describe 'Creation date: 2021-01-01' do
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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Created">2021-01-01</date>
          </dates>
        XML
      end
    end
  end

  describe 'Creation date range: 2020-01-01 to 2021-01-01' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"

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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Created">2020-01-01/2021-01-01</date>
          </dates>
        XML
      end
    end
  end

  describe 'Approximate single creation date' do
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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900</date>
          </dates>
        XML
      end
    end
  end

  describe 'Approximate creation start date: approx. 1900' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"

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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
          </dates>
        XML
      end
    end
  end

  describe 'Approximate creation end date: approx. 1900' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"

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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
          </dates>
        XML
      end
    end
  end

  describe 'Approximate creation date range: approx. 1900' do
    # Per Arcadia: "the pattern is for properties to be at the highest level to which they apply"
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
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <dates>
            <date dateType="Creation" dateInformation="Approximate">1900/1910</date>
          </dates>
        XML
      end
    end
  end

  describe 'No publication date provided, embargoed until: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'release',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <publicationYear>2022</publicationYear>
          <dates>
            <date dateType="Available">2022-01-01</date>
          </dates>
        XML
      end
    end
  end

  describe 'Publication date entered as: 2021-01-01, embargoed until: 2022-01-01' do
    xit 'not implemented' do
      let(:cocina) do
        {
          event: [
            {
              type: 'release',
              date: [
                {
                  value: '2022-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            },
            {
              type: 'publication',
              date: [
                {
                  value: '2021-01-01',
                  type: 'publication',
                  encoding: {
                    code: 'w3cdtf'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <publicationYear>2021</publicationYear>
          <dates>
            <date dateType="Issued">2021-01-01</date>
            <date dateType="Available">2022-01-01</date>
          </dates>
        XML
      end
    end
  end
end
