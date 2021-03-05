# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  describe 'Subject with only titleInfo subelement' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo authority="lcsh" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79018834">
              <title>Beowulf</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Beowulf',
              type: 'title',
              uri: 'http://id.loc.gov/authorities/names/n79018834',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Subject with only titleInfo subelement, multipart title' do
    # Example from gp286dy1254
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo>
              <title>Bible. English 1975</title>
              <partName>Jonah. English 1975</partName>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Bible. English 1975',
                  type: 'main title'
                },
                {
                  value: 'Jonah. English 1975',
                  type: 'part name'
                }
              ],
              type: 'title',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'With language attributes on subject element' do
    # adapted from xr748qv0599
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject lang="chi" script="Latn" authority="lcsh">
            <titleInfo>
              <title>Xin guo min yun dong</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              source: {
                code: 'lcsh'
              },
              valueLanguage: {
                code: 'chi',
                source: {
                  code: 'iso639-2b'
                },
                valueScript: {
                  code: 'Latn',
                  source: {
                    code: 'iso15924'
                  }
                }
              },
              value: 'Xin guo min yun dong',
              type: 'title'
            }
          ]
        }
      end
    end
  end

  describe 'Uniform title' do
    xit 'unimplemented spec' do
      let(:druid) { 'druid:mx928ks3963' }

      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n88244749">
              <title>Microsoft PowerPoint (Computer file)</title>
            </titleInfo>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              groupedValue: [
                {
                  value: 'Microsoft PowerPoint (Computer file)',
                  type: 'uniform',
                  uri: 'http://id.loc.gov/authorities/names/n88244749',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'title',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end
end
