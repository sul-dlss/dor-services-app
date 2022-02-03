# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject cartographic <--> cocina mappings' do
  describe 'Cartographic subject' do
    # Omit encoding for mapping purposes.
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: '1:22,000,000',
              type: 'map scale'
            },
            {
              value: 'Conic proj',
              type: 'map projection'
            }
          ],
          subject: [
            {
              value: 'E 72°--E 148°/N 13°--N 18°',
              type: 'map coordinates'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple cartographic subjects (mapped from ISO 19139)' do
    # Based on druid:jw325wd1971
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>(E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ)</coordinates>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>EPSG::4326</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
        XML
      end

      # Put all subject/cartographics without authority together
      # Authority attributes must be at subject level, so each subject/cartographics with authority gets its own subject
      let(:roundtrip_mods) do
        <<~XML
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <projection>EPSG::4326</projection>
            </cartographics>
          </subject>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Scale not given.',
              type: 'map scale'
            },
            {
              value: 'Custom projection',
              type: 'map projection'
            },
            {
              value: 'EPSG::4326',
              type: 'map projection',
              uri: 'http://opengis.net/def/crs/EPSG/0/4326',
              source: {
                code: 'EPSG'
              },
              displayLabel: 'WGS84'
            }
          ],
          subject: [
            {
              value: 'E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ',
              type: 'map coordinates'
            }
          ]
        }
      end
    end
  end

  describe 'Multiple cartographic subjects with altRepGroup' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject altRepGroup="2">
            <cartographics>
              <scale>Scale 1:650,000.</scale>
            </cartographics>
          </subject>
          <subject altRepGroup="2">
            <cartographics>
              <scale>&#x6BD4;&#x4F8B;&#x5C3A; 1:650,000.</scale>
            </cartographics>
          </subject>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              parallelValue: [
                {
                  value: 'Scale 1:650,000.',
                  type: 'map scale'
                },
                {
                  value: '比例尺 1:650,000.',
                  type: 'map scale'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Cartographic subject with multiple scales' do
    # Adapted from ky585kf9485
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <cartographics>
              <scale>Scale: 40 wan fen yi zhi ti chi.</scale>
              <scale>Scale: 1:400,000.</scale>
            </cartographics>
          </subject>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              groupedValue: [
                {
                  value: 'Scale: 40 wan fen yi zhi ti chi.'
                },
                {
                  value: 'Scale: 1:400,000.'
                }
              ],
              type: 'map scale'
            }
          ]
        }
      end
    end
  end

  describe 'Cartographic subject with multiple coordinate representations' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>W0750700 W0741200 N0443400 N0431200</coordinates>
            </cartographics>
          </subject>
          <subject>
            <cartographics>
              <scale>Scale ca. 1:126,720. 1 in. to 2 miles.</scale>
            </cartographics>
            <cartographics>
              <coordinates>(W 75⁰07ʹ00ʹ--W 74⁰12ʹ00ʹ/N 44⁰34ʹ00ʹ--N 43⁰12ʹ00ʹ)</coordinates>
            </cartographics>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
           <subject>
            <cartographics>
              <scale>Scale ca. 1:126,720. 1 in. to 2 miles.</scale>
              <coordinates>W0750700 W0741200 N0443400 N0431200</coordinates>
              <coordinates>W 75⁰07ʹ00ʹ--W 74⁰12ʹ00ʹ/N 44⁰34ʹ00ʹ--N 43⁰12ʹ00ʹ</coordinates>
            </cartographics>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'map coordinates',
              value: 'W0750700 W0741200 N0443400 N0431200'
            },
            {
              type: 'map coordinates',
              value: 'W 75⁰07ʹ00ʹ--W 74⁰12ʹ00ʹ/N 44⁰34ʹ00ʹ--N 43⁰12ʹ00ʹ'
            }
          ],
          form: [
            {
              value: 'Scale ca. 1:126,720. 1 in. to 2 miles.',
              type: 'map scale'
            }
          ]
        }
      end
    end
  end
end
