# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS identifier <--> cocina mappings' do
  describe 'Identifier with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="isbn">1234 5678 9203</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '1234 5678 9203',
              type: 'ISBN',
              note: [
                {
                  type: 'type',
                  value: 'isbn',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/isbn',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'URI as identifier' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              uri: 'https://www.wikidata.org/wiki/Q146',
              note: [
                {
                  type: 'type',
                  value: 'uri',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/uri',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Identifier with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier displayLabel="Accession number">1980-12345</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '1980-12345',
              displayLabel: 'Accession number'
            }
          ]
        }
      end
    end
  end

  describe 'Invalid identifier' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="lccn" invalid="yes">sn 87042262</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: 'sn 87042262',
              type: 'LCCN',
              status: 'invalid',
              note: [
                {
                  type: 'type',
                  value: 'lccn',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/lccn',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual identifier' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier altRepGroup="1">zeng bu</identifier>
          <identifier altRepGroup="1">增補</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              parallelValue: [
                {
                  value: 'zeng bu'
                },
                {
                  value: '增補'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # dev added specs below

  context 'with an identifier that is from Standard Identifier Source Codes' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: 'http://bnf.fr/ark:/13030/tf5p30086k',
              type: 'ARK',
              note: [
                {
                  type: 'type',
                  value: 'ark',
                  source: {
                    value: 'Standard Identifier Source Codes'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with an identifier with an unknown MODS type that matches a Cocina type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="oclc">123456789203</identifier>
        XML
      end

      # capitalized OCLC
      let(:roundtrip_mods) do
        <<~XML
          <identifier type="OCLC">123456789203</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '123456789203',
              type: 'OCLC'
            }
          ]
        }
      end
    end

    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          identifier: [
            {
              value: '123456789203',
              type: 'OCLC'
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <identifier type="OCLC">123456789203</identifier>
        XML
      end
    end
  end

  context 'with an identifier with an unknown MODS type that does not match a Cocina type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="xyz">123456789203</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '123456789203',
              type: 'xyz'
            }
          ]
        }
      end
    end
  end

  context 'when identifier is various flavors of missing' do
    context 'when cocina is empty array' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            identifier: []
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) { '' }
      end
    end

    context 'when MODS has no elements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) { '' }

        let(:cocina) do
          {
          }
        end
      end
    end

    context 'when cocina is array with empty hash' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            identifier: [{}]
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) do
          <<~XML
            <identifier/>
          XML
        end
      end
    end

    context 'when MODS is empty identifier element with no attributes' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <identifier/>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
          XML
        end

        let(:cocina) do
          {
          }
        end
      end
    end
  end
end
