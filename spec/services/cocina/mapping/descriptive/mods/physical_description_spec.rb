# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS physicalDescription <--> cocina mappings' do
  describe 'Single physical description with all subelements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <reformattingQuality>access</reformattingQuality>
            <internetMediaType>image/jpeg</internetMediaType>
            <extent>1 sheet</extent>
            <digitalOrigin>reformatted digital</digitalOrigin>
            <note displayLabel="Condition">Small tear at top right corner.</note>
            <note displayLabel="Material" type="material">Paper</note>
            <note displayLabel="Layout" type="layout">34 and 24 lines to a page</note>
            <note displayLabel="Height (mm)" type="dimensions">210</note>
            <note displayLabel="Width (mm)" type="dimensions">146</note>
            <note displayLabel="Collation" type="collation">1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).</note>
            <note displayLabel="Writing" type="handNote">change of hand</note>
            <note displayLabel="Foliation" type="foliation">ff. i + 1-51 + ii-iii</note>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'ink on paper',
                  type: 'form'
                },
                {
                  value: 'access',
                  type: 'reformatting quality',
                  source: {
                    value: 'MODS reformatting quality terms'
                  }
                },
                {
                  value: 'image/jpeg',
                  type: 'media type',
                  source: {
                    value: 'IANA media types'
                  }
                },
                {
                  value: '1 sheet',
                  type: 'extent'
                },
                {
                  value: 'reformatted digital',
                  type: 'digital origin',
                  source: {
                    value: 'MODS digital origin terms'
                  }
                }
              ],
              note: [
                {
                  value: 'Small tear at top right corner.',
                  displayLabel: 'Condition'
                },
                {
                  value: 'Paper',
                  displayLabel: 'Material',
                  type: 'material'
                },
                {
                  value: '34 and 24 lines to a page',
                  displayLabel: 'Layout',
                  type: 'layout'
                },
                {
                  value: '210',
                  displayLabel: 'Height (mm)',
                  type: 'dimensions'
                },
                {
                  value: '146',
                  displayLabel: 'Width (mm)',
                  type: 'dimensions'
                },
                {
                  value: '1(8) 2(10) 3(8) 4(8) 5 (two) || a(16) (wants 16).',
                  displayLabel: 'Collation',
                  type: 'collation'
                },
                {
                  value: 'change of hand',
                  displayLabel: 'Writing',
                  type: 'handNote'
                },
                {
                  value: 'ff. i + 1-51 + ii-iii',
                  displayLabel: 'Foliation',
                  type: 'foliation'
                }
              ]

            }
          ]
        }
      end
    end
  end

  describe 'Multiple physical descriptions' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form>audio recording</form>
            <extent>1 audiocassette</extent>
          </physicalDescription>
          <physicalDescription>
            <form>transcript</form>
            <extent>5 pages</extent>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              structuredValue: [
                {
                  value: 'audio recording',
                  type: 'form'
                },
                {
                  value: '1 audiocassette',
                  type: 'extent'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'transcript',
                  type: 'form'
                },
                {
                  value: '5 pages',
                  type: 'extent'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Form with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription>
            <form authority="aat" authorityURI="http://vocab.getty.edu/aat/"
              valueURI="http://vocab.getty.edu/aat/300041356">mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'mezzotints (prints)',
              type: 'form',
              uri: 'http://vocab.getty.edu/aat/300041356',
              source: {
                code: 'aat',
                uri: 'http://vocab.getty.edu/aat/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Display label with single form' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>metal embossed on wood</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'metal embossed on wood',
              type: 'form',
              displayLabel: 'Medium'
            }
          ]
        }
      end
    end
  end

  describe 'Display label with multiple form' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <physicalDescription displayLabel="Medium">
            <form>metal embossed on wood</form>
            <form>mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              displayLabel: 'Medium',
              structuredValue: [
                {
                  value: 'metal embossed on wood',
                  type: 'form'
                },
                {
                  value: 'mezzotints (prints)',
                  type: 'form'
                }

              ]

            }
          ]
        }
      end
    end
  end
end
