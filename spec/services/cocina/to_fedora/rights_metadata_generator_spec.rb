# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::RightsMetadataGenerator do
  subject(:generate) do
    described_class.generate(item: item, object: object)
  end

  context 'with a world-readable item w/ a mix of dark and world-accessible files' do
    let(:cocina) do
      <<~JSON
        {
          "type": "http://cocina.sul.stanford.edu/models/media.jsonld",
          "externalIdentifier": "druid:bh113xd8812",
          "label": "12 Kontretaenze, WoO 14",
          "version": 7,
          "access": {
            "access": "world",
            "copyright": "default copyright",
            "download": "none",
            "useAndReproductionStatement": "default use and reproduction"
          },
          "administrative": {
            "hasAdminPolicy": "druid:sc012gz0974",
            "partOfProject": "cocina fixture"
          },
          "description": {
            "title": [
              {
                "value": "rights mapping test"
              }
            ],
            "purl": "http://purl.stanford.edu/bh113xd8812",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "a_test:id5",
            "catalogLinks": [
              {
                "catalog": "symphony",
                "catalogRecordId": "444"
              }
            ]
          },
          "structural": {
            "contains": [
              {
                "type": "http://cocina.sul.stanford.edu/models/fileset.jsonld",
                "externalIdentifier": "bh113xd8812_1",
                "label": "Audio file",
                "version": 7,
                "structural": {
                  "contains": [
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:bh113xd8812/bh113xd8812_sample_01_00_pm.wav",
                      "label": "bh113xd8812_sample_01_00_pm.wav",
                      "filename": "bh113xd8812_sample_01_00_pm.wav",
                      "size": 299569842,
                      "version": 7,
                      "hasMimeType": "audio/x-wav",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "ccde1331b5bc6c3dce0231c352c7a11f1fd3e77f"
                        },
                        {
                          "type": "md5",
                          "digest": "d46055f03b4a9dc30fcfdfebea473127"
                        }
                      ],
                      "access": {
                        "access": "dark",
                        "download": "none"
                      },
                      "administrative": {
                        "sdrPreserve": true,
                        "shelve": false
                      }
                    },
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:bh113xd8812/bh113xd8812_sample_01_00_sh.wav",
                      "label": "bh113xd8812_sample_01_00_sh.wav",
                      "filename": "bh113xd8812_sample_01_00_sh.wav",
                      "size": 91743738,
                      "version": 7,
                      "hasMimeType": "audio/x-wav",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "a9cb4668c42c5416a301759ff40fe365ea2467a3"
                        },
                        {
                          "type": "md5",
                          "digest": "188c0c972bc039c679bf984e75c7500e"
                        }
                      ],
                      "access": {
                        "access": "dark",
                        "download": "none"
                      },
                      "administrative": {
                        "sdrPreserve": true,
                        "shelve": false
                      }
                    },
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:bh113xd8812/bh113xd8812_sample_01_00_sl.m4a",
                      "label": "bh113xd8812_sample_01_00_sl.m4a",
                      "filename": "bh113xd8812_sample_01_00_sl.m4a",
                      "size": 16798755,
                      "version": 7,
                      "hasMimeType": "audio/mp4",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "8d95b3b77f900b6d229ee32d05f927d75cbce032"
                        },
                        {
                          "type": "md5",
                          "digest": "b044b593d0d444180e82de064594339a"
                        }
                      ],
                      "access": {
                        "access": "world",
                        "download": "none"
                      },
                      "administrative": {
                        "sdrPreserve": true,
                        "shelve": true
                      }
                    }
                  ]
                }
              },
              {
                "type": "http://cocina.sul.stanford.edu/models/fileset.jsonld",
                "externalIdentifier": "bh113xd8812_2",
                "label": "Program PDF",
                "version": 7,
                "structural": {
                  "contains": [
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:bh113xd8812/bh113xd8812_sample_md.pdf",
                      "label": "bh113xd8812_sample_md.pdf",
                      "filename": "bh113xd8812_sample_md.pdf",
                      "size": 930089,
                      "version": 7,
                      "hasMimeType": "application/pdf",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "3b342f7b87f126997088720c1220122d41c8c159"
                        },
                        {
                          "type": "md5",
                          "digest": "6ed0004f39657ff81dff7b2b017fb9d9"
                        }
                      ],
                      "access": {
                        "access": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "sdrPreserve": true,
                        "shelve": true
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      JSON
    end
    let(:item) { instantiate_fixture('druid:bh113xd8812', Dor::Item) }
    let(:object) do
      Cocina::Models::DRO.new(JSON.parse(cocina))
    end

    it 'maps object- and file-level rights metadata' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
          <access type="read">
            <file>bh113xd8812_sample_md.pdf</file>
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="creativeCommons">Public Domain Mark 1.0</human>
            <machine type="creativeCommons" uri="https://creativecommons.org/publicdomain/mark/1.0/">pdm</machine>
            <human type="useAndReproduction">default use and reproduction</human>
          </use>
          <copyright>
            <human>default copyright</human>
          </copyright>
        </rightsMetadata>
      XML
    end
  end
end
