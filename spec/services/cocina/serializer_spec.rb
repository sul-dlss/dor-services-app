# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Serializer do
  let(:dro) do
    Cocina::Models.build(
      {
        'type' => Cocina::Models::ObjectType.object,
        'externalIdentifier' => 'druid:ft609gr4031',
        'label' => 'SUL Logo for golden_wonder_millet',
        'version' => 1,
        'access' => {
          'view' => 'citation-only',
          'download' => 'none',
          'embargo' => {
            'view' => 'world',
            'download' => 'world',
            'releaseDate' => DateTime.parse('2022-02-25T00:00:00.000+00:00')
          },
          'useAndReproductionStatement' => 'User agrees that, where applicable, content will not be used.',
          'license' => 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
        },
        'administrative' => {
          'hasAdminPolicy' => 'druid:zw306xn5593'
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
              'type' => Cocina::Models::FileSetType.file,
              'externalIdentifier' => 'https://cocina.sul.stanford.edu/fileSet/e4c2b834-90ce-4be8-b9fa-445df89f5f10',
              'label' => '', 'version' => 1,
              'structural' => {
                'contains' => [
                  {
                    'type' => Cocina::Models::ObjectType.file,
                    'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/8ee2d21b-9183-4df6-9813-c0a104b329ce',
                    'label' => 'sul-logo.png',
                    'filename' => 'sul-logo.png',
                    'size' => 19_823,
                    'version' => 1,
                    'hasMimeType' => 'image/png',
                    'sdrGeneratedText' => false,
                    'correctedForAccessibility' => false,
                    'hasMessageDigests' => [
                      { 'type' => 'sha1',
                        'digest' => 'b5f3221455c8994afb85214576bc2905d6b15418' },
                      { 'type' => 'md5', 'digest' => '7142ce948827c16120cc9e19b05acd49' }
                    ],
                    'access' => { 'view' => 'world', 'download' => 'world' },
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
        },
        identification: { sourceId: 'sul:123' }
      }
    )
  end

  let(:dro_with_metadata) { Cocina::Models.with_metadata(dro, '1', created: DateTime.now) }

  let(:expected_serialized) do
    {
      '_aj_serialized' => 'Cocina::Serializer',
      cocinaVersion: Cocina::Models::VERSION,
      type: Cocina::Models::ObjectType.object,
      externalIdentifier: 'druid:ft609gr4031',
      label: 'SUL Logo for golden_wonder_millet',
      version: 1,
      access: {
        view: 'citation-only',
        download: 'none',
        controlledDigitalLending: false,
        embargo: {
          view: 'world',
          download: 'world',
          controlledDigitalLending: false,
          releaseDate: '2022-02-25T00:00:00.000+00:00'
        },
        useAndReproductionStatement: 'User agrees that, where applicable, content will not be used.',
        license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
      },
      administrative: {
        hasAdminPolicy: 'druid:zw306xn5593'
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
      identification: {
        catalogLinks: [],
        sourceId: 'sul:123'
      },
      structural: {
        contains: [{
          type: Cocina::Models::FileSetType.file,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e4c2b834-90ce-4be8-b9fa-445df89f5f10',
          label: '',
          version: 1,
          structural: {
            contains: [{
              type: Cocina::Models::ObjectType.file,
              externalIdentifier: 'https://cocina.sul.stanford.edu/file/8ee2d21b-9183-4df6-9813-c0a104b329ce',
              label: 'sul-logo.png',
              filename: 'sul-logo.png',
              size: 19_823,
              version: 1,
              hasMimeType: 'image/png',
              sdrGeneratedText: false,
              correctedForAccessibility: false,
              hasMessageDigests: [{
                type: 'sha1',
                digest: 'b5f3221455c8994afb85214576bc2905d6b15418'
              }, {
                type: 'md5',
                digest: '7142ce948827c16120cc9e19b05acd49'
              }],
              access: {
                view: 'world',
                download: 'world',
                controlledDigitalLending: false
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
    }
  end

  describe '.serialize' do
    it 'serializes DROs' do
      expect(ActiveJob::Serializers.serialize(dro)).to eq expected_serialized
    end

    it 'serializes DROWithMetadatas' do
      expect(ActiveJob::Serializers.serialize(dro_with_metadata)).to eq expected_serialized
    end
  end

  describe '.deserializes' do
    it 'deserializes DROs' do
      expect(ActiveJob::Serializers.deserialize(expected_serialized)).to eq dro
    end
  end
end
