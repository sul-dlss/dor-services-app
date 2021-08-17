# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for relatedItem' do
  describe 'Related citation' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <note type="preferred citation">Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.</note>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              note: [
                {
                  value: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.',
                  type: 'preferred citation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related link with title' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <titleInfo>
              <title>A paper</title>
            </titleInfo>
            <location>
              <url>https://www.example.com/paper.html</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'A paper'
                }
              ],
              access: {
                url: [
                  {
                    value: 'https://www.example.com/paper.html'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end

  describe 'Related link without title' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <location>
              <url>https://www.example.com/paper.html</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              access: {
                url: [
                  {
                    value: 'https://www.example.com/paper.html'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'with location/url, starting from cocina' do
    # based on wm437jj2051, tx853fp2857 migrated from Hydrus
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          relatedResource: [
            {
              title: [
                {
                  value: 'Software Carpentry'
                }
              ],
              access: {
                url: [
                  {
                    value: 'http://software-carpentry.org/'
                  }
                ]
              }
            },
            {
              title: [
                {
                  value: 'Data Management Services Events'
                }
              ],
              access: {
                url: [
                  {
                    value: 'http://library.stanford.edu/research/data-management-services/events'
                  }
                ]
              }
            },
            {
              title: [
                {
                  value: 'Software Carpentry Workshop recordings from August 14, 2014'
                }
              ],
              purl:	'https://purl.stanford.edu/tx853fp2857',
              access: {
                digitalRepository: [
                  {
                    value: 'Stanford Digital Repository'
                  }
                ]
              }
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <relatedItem>
            <titleInfo>
              <title>Software Carpentry</title>
            </titleInfo>
            <location>
              <url>http://software-carpentry.org/</url>
            </location>
          </relatedItem>
          <relatedItem>
            <titleInfo>
              <title>Data Management Services Events</title>
            </titleInfo>
            <location>
              <url>http://library.stanford.edu/research/data-management-services/events</url>
            </location>
          </relatedItem>
          <relatedItem>
            <titleInfo>
              <title>Software Carpentry Workshop recordings from August 14, 2014</title>
            </titleInfo>
            <location>
              <url usage="primary display">https://purl.stanford.edu/tx853fp2857</url>
            </location>
          </relatedItem>
        XML
      end
    end
  end
end
