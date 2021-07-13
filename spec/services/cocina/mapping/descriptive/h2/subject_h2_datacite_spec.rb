# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for FAST subjects' do
  describe 'FAST topic' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Marine biology',
              type: 'topic',
              uri: 'http://id.worldcat.org/fast/1009447',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST personal name' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Anning, Mary, 1799-1847',
              type: 'person',
              uri: 'http://id.worldcat.org/fast/270223',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">Anning, Mary, 1799-1847</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST corporate name' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'United States. National Oceanic and Atmospheric Administration',
              type: 'organization',
              uri: 'http://id.worldcat.org/fast/529308',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/529308">United States. National Oceanic and Atmospheric Administration</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST meeting name' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'International Conference on Port and Ocean Engineering Under Arctic Conditions',
              type: 'conference',
              uri: 'http://id.worldcat.org/fast/1405317',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1405317">International Conference on Port and Ocean Engineering Under Arctic Conditions</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST geographic name' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Pacific Ocean',
              type: 'place',
              uri: 'http://id.worldcat.org/fast/1243528',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1243528">Pacific Ocean</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST event' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'International Year of the Ocean (1998)',
              type: 'event',
              uri: 'http://id.worldcat.org/fast/976704',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              },
              displayLabel: 'Event'
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/976704">International Year of the Ocean</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST title' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Missa Ave Maris Stella (Josquin, des Prez)',
              type: 'title',
              uri: 'http://id.worldcat.org/fast/1399391',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1399391">Missa Ave Maris Stella (Josquin, des Prez)</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST time period' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: '1689-1725',
              type: 'time',
              uri: 'http://id.worldcat.org/fast/1355694',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1355694">1689-1725</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'FAST form/genre' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Watercolors',
              type: 'genre',
              uri: 'http://id.worldcat.org/fast/1986272',
              source: {
                code: 'fast',
                uri: 'http://id.worldcat.org/fast/'
              }
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1986272">Watercolors</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'Non-FAST term' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Brooding sea stars',
              type: 'topic'
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject>Brooding sea stars</subject>
          </subjects>
        XML
      end
    end
  end

  describe 'Multiple terms' do
    xit 'not implemented' do
      let(:cocina) do
        {
          subject: [
            {
              value: 'Brooding sea stars',
              type: 'topic'
            },
            {
              value: 'Sea stars in motion',
              type: 'topic'
            }
          ]
        }
      end

      let(:datacite) do
        <<~XML
          <subjects>
            <subject>Brooding sea stars</subject>
            <subject>Sea stars in motion</subject>
          </subjects>
        XML
      end
    end
  end
end
