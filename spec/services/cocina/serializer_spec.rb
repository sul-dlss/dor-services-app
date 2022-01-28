# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Serializer do
  let(:serializer) { described_class.new }

  let(:dro) do
    Cocina::Models.build(
      {
        'type' => 'http://cocina.sul.stanford.edu/models/object.jsonld',
        'externalIdentifier' => 'druid:ft609gr4031',
        'label' => 'SUL Logo for golden_wonder_millet',
        'version' => 1,
        'access' => {
          'access' => 'citation-only',
          'download' => 'none',
          'embargo' => {
            'access' => 'world',
            'download' => 'world',
            'releaseDate' => DateTime.parse('2022-02-25T00:00:00.000+00:00')
          },
          'useAndReproductionStatement' => 'User agrees that, where applicable, content will not be used.',
          'license' => 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
        },
        'administrative' => {
          'hasAdminPolicy' => 'druid:zw306xn5593',
          'partOfProject' => 'H2'
        },
        'description' => {
          'title' => [
            { 'value' => 'SUL Logo for golden_wonder_millet' }
          ],
          'purl' => 'https://purl.stanford.edu/ft609gr4031'
        },
        'structural' => {
          'contains' => [
            {
              'type' => 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
              'externalIdentifier' => 'http://cocina.sul.stanford.edu/fileSet/e4c2b834-90ce-4be8-b9fa-445df89f5f10',
              'label' => '', 'version' => 1,
              'structural' => {
                'contains' => [
                  {
                    'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    'externalIdentifier' => 'http://cocina.sul.stanford.edu/file/8ee2d21b-9183-4df6-9813-c0a104b329ce',
                    'label' => 'sul-logo.png',
                    'filename' => 'sul-logo.png',
                    'size' => 19823,
                    'version' => 1,
                    'hasMimeType' => 'image/png',
                    'hasMessageDigests' => [{ 'type' => 'sha1', 'digest' => 'b5f3221455c8994afb85214576bc2905d6b15418' }, { 'type' => 'md5', 'digest' => '7142ce948827c16120cc9e19b05acd49' }],
                    'access' => { 'access' => 'world', 'download' => 'world' },
                    'administrative' => {
                      'publish' => true,
                      'sdrPreserve' => true,
                      'shelve' => true
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    )
  end

  let(:json) do
    {
      cocinaVersion: Cocina::Models::VERSION,
      type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
      externalIdentifier: 'druid:ft609gr4031',
      label: 'SUL Logo for golden_wonder_millet',
      version: 1,
      access: {
        access: 'citation-only',
        download: 'none',
        embargo: {
          access: 'world',
          download: 'world',
          releaseDate: '2022-02-25T00:00:00.000+00:00'
        },
        useAndReproductionStatement: 'User agrees that, where applicable, content will not be used.',
        license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
      },
      administrative: {
        hasAdminPolicy: 'druid:zw306xn5593',
        releaseTags: [],
        partOfProject: 'H2'
      },
      description: {
        title: [{
          structuredValue: [],
          parallelValue: [],
          groupedValue: [],
          value: 'SUL Logo for golden_wonder_millet',
          identifier: [],
          note: [],
          appliesTo: []
        }],
        contributor: [],
        event: [],
        form: [],
        geographic: [],
        language: [],
        note: [],
        identifier: [],
        subject: [],
        relatedResource: [],
        marcEncodedData: [],
        purl: 'https://purl.stanford.edu/ft609gr4031'
      },
      structural: {
        contains: [{
          type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
          externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/e4c2b834-90ce-4be8-b9fa-445df89f5f10',
          label: '',
          version: 1,
          structural: {
            contains: [{
              type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
              externalIdentifier: 'http://cocina.sul.stanford.edu/file/8ee2d21b-9183-4df6-9813-c0a104b329ce',
              label: 'sul-logo.png',
              filename: 'sul-logo.png',
              size: 19823,
              version: 1,
              hasMimeType: 'image/png',
              hasMessageDigests: [{
                type: 'sha1',
                digest: 'b5f3221455c8994afb85214576bc2905d6b15418'
              }, {
                type: 'md5',
                digest: '7142ce948827c16120cc9e19b05acd49'
              }],
              access: {
                access: 'world',
                download: 'world'
              },
              administrative: {
                publish: true,
                sdrPreserve: true,
                shelve: true
              }
            }]
          }
        }],
        hasMemberOrders: [],
        isMemberOf: []
      }
    }.to_json
  end

  describe '.serialize?' do
    it 'serializes DROs' do
      expect(serializer.serialize?(dro)).to be true
    end

    it 'does not serialize non-DROs' do
      expect(serializer.serialize?('not a DRO')).to be false
    end
  end

  describe '.serialize' do
    it 'serializes DROs' do
      expect(serializer.serialize(dro)).to eq json
    end
  end

  describe '.deserializes' do
    it 'deserializes DROs' do
      expect(serializer.deserialize(json)).to eq dro
    end
  end
end
