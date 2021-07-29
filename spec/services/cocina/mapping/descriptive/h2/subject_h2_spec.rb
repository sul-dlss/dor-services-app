# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for FAST subjects' do
  describe 'FAST topic' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST personal name' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <name type="personal" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">
              <namePart>Anning, Mary, 1799-1847</namePart>
            </name>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST corporate name' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <name type="corporate" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/529308">
              <namePart>United States. National Oceanic and Atmospheric Administration</namePart>
            </name>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST meeting name' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <name type="conference" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1405317">
              <namePart>International Conference on Port and Ocean Engineering Under Arctic Conditions</namePart>
            </name>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST geographic name' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <geographic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1243528">Pacific Ocean</geographic>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST event' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast" displayLabel="Event">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/976704">International Year of the Ocean (1998)</topic>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST title' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <titleInfo authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1399391">
              <title>Missa Ave Maris Stella (Josquin, des Prez)</title>
            </titleInfo>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST time period' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <temporal authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1355694">1689-1725</temporal>
          </subject>
        XML
      end

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
    end
  end

  describe 'FAST form/genre' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject authority="fast">
            <genre authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1986272">Watercolors</genre>
          </subject>
        XML
      end

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
    end
  end

  describe 'Non-FAST term' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic>Brooding sea stars</topic>
          </subject>
        XML
      end

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
    end
  end

  describe 'Multiple terms' do
    it_behaves_like 'cocina MODS mapping' do
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

      let(:mods) do
        <<~XML
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
          <subject authority="fast">
            <geographic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1243528">Pacific Ocean</geographic>
          </subject>
          <subject>
            <topic>Brooding sea stars</topic>
          </subject>
          <subject>
            <topic>Sea stars in motion</topic>
          </subject>
        XML
      end
    end
  end
end
