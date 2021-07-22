# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for FAST subjects' do
  # NOTE: Because we haven't set a title in this Cocina::Models::Description, it will not validate against the openapi.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:subjects_attributes) { Cocina::ToDatacite::Subject.subjects_attributes(cocina_description) }

  describe 'FAST topic' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Marine biology',
            subjectScheme: 'fast',
            valueURI: 'http://id.worldcat.org/fast/1009447',
            schemeURI: 'http://id.worldcat.org/fast/'
          }
        ]
      )
    end
  end

  describe 'FAST personal name' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">Anning, Mary, 1799-1847</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Anning, Mary, 1799-1847',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/270223'
          }
        ]
      )
    end
  end

  describe 'FAST corporate name' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/529308">United States. National Oceanic and Atmospheric Administration</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'United States. National Oceanic and Atmospheric Administration',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/529308'
          }
        ]
      )
    end
  end

  describe 'FAST meeting name' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1405317">International Conference on Port and Ocean Engineering Under Arctic Conditions</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'International Conference on Port and Ocean Engineering Under Arctic Conditions',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1405317'
          }
        ]
      )
    end
  end

  describe 'FAST geographic name' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1243528">Pacific Ocean</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Pacific Ocean',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1243528'
          }
        ]
      )
    end
  end

  describe 'FAST event' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/976704">International Year of the Ocean</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'International Year of the Ocean (1998)',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/976704'
          }
        ]
      )
    end
  end

  describe 'FAST title' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1399391">Missa Ave Maris Stella (Josquin, des Prez)</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Missa Ave Maris Stella (Josquin, des Prez)',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1399391'
          }
        ]
      )
    end
  end

  describe 'FAST time period' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1355694">1689-1725</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: '1689-1725',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1355694'
          }
        ]
      )
    end
  end

  describe 'FAST form/genre' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject subjectScheme="fast" schemeURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1986272">Watercolors</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Watercolors',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1986272'
          }
        ]
      )
    end
  end

  describe 'Non-FAST term' do
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject>Brooding sea stars</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Brooding sea stars'
          }
        ]
      )
    end
  end

  describe 'Multiple terms' do
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
          },
          {
            value: 'Pacific Ocean',
            type: 'place',
            uri: 'http://id.worldcat.org/fast/1243528',
            source: {
              code: 'fast',
              uri: 'http://id.worldcat.org/fast/'
            }
          },
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

    it 'populates subjects_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <subjects>
      #       <subject>Brooding sea stars</subject>
      #       <subject>Sea stars in motion</subject>
      #     </subjects>
      #   XML
      # end
      expect(subjects_attributes).to eq(
        [
          {
            subject: 'Marine biology',
            subjectScheme: 'fast',
            valueURI: 'http://id.worldcat.org/fast/1009447',
            schemeURI: 'http://id.worldcat.org/fast/'
          },
          {
            subject: 'Pacific Ocean',
            subjectScheme: 'fast',
            schemeURI: 'http://id.worldcat.org/fast/',
            valueURI: 'http://id.worldcat.org/fast/1243528'
          },
          {
            subject: 'Brooding sea stars'
          },
          {
            subject: 'Sea stars in motion'
          }
        ]
      )
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina subject array has empty hash' do
    let(:cocina) do
      {
        subject: [
          {
          }
        ]
      }
    end

    it 'subjects_attributes is empty hash' do
      expect(subjects_attributes).to eq([])
    end
  end

  context 'when cocina subject is empty array' do
    let(:cocina) do
      {
        subject: []
      }
    end

    it 'subjects_attributes is empty hash' do
      expect(subjects_attributes).to eq([])
    end
  end

  context 'when cocina has no subject' do
    let(:cocina) do
      {
      }
    end

    it 'subjects_attributes is empty hash' do
      expect(subjects_attributes).to eq([])
    end
  end
end
