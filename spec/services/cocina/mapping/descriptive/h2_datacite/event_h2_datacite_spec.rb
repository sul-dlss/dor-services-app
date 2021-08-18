# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for event (h2 specific)' do
  # Use embargo year from cocina access if present, otherwise use current year
  describe 'Publication date: 2021-01-01, current year: 2022, no embargo' do
    xit 'not implemented' do
      let(:cocina) do
        {
          description: {
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
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end

  describe 'Publication date: 2021-01-01, current year: 2022, embargo year: 2023' do
    xit 'not implemented' do
      let(:cocina) do
        {
          access: {
            embargo: {
              releaseDate: '2023-01-01T00:00:00.000+00:00'
            }
          },
          description: {
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
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2023',
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end

  describe 'Creation date: 2021-01-01, current year: 2022, no embargo' do
    xit 'not implemented' do
      let(:cocina) do
        {
          description: {
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
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2022',
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end

  describe 'Creation date: 2021-01-01, current year: 2022, embargo year: 2023' do
    xit 'not implemented' do
      let(:cocina) do
        {
          access: {
            embargo: {
              releaseDate: '2023-01-01T00:00:00.000+00:00'
            }
          },
          description: {
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
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              publicationYear: '2023',
              publisher: 'Stanford Digital Repository'
            }
          }
        }
      end
    end
  end
end
