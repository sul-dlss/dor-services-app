# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for event (h2 specific)' do
  describe 'Publication date: 2021-01-01, current year: 2022' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <publicationYear>2022</publicationYear>
            <publisher>Stanford Digital Repository</publisher>
          </extension>
        XML
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              publisher: 'Stanford Digital Repository',
              publicationYear: '2022'
            }
          }
        }
      end
    end
  end

  describe 'Publication date: 2021-01-01, current year: 2022, cited publisher: Stanford University Press' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
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

      let(:datacite) do
        {
          data: {
            attributes: {
              creators: [
                {
                  name: 'Stanford University Press',
                  nameType: 'Organizational'
                }
              ],
              publisher: 'Stanford Digital Repository',
              publicationYear: '2022'
            }
          }
        }
      end
    end
  end
end
