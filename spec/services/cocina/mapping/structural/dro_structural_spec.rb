# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'DRO Structural Fedora Cocina mapping' do
  # Required: content_metadata_xml, dro_type, bare_druid, version, collection_ids, rights_metadata_xml, cocina_structural_props
  # Optional: roundtrip_content_metadata_xml

  let(:full_druid) { "druid:#{bare_druid}" }
  let(:fedora_item) { Dor::Item.new }
  let(:fedora_item_mock) do
    instance_double(Dor::Item,
                    pid: full_druid,
                    id: full_druid,
                    current_version: version,
                    collections: collection_ids.map { |coll_id| Dor::Collection.new(pid: coll_id) },
                    contentMetadata: Dor::ContentMetadataDS.from_xml(content_metadata_xml),
                    rightsMetadata: Dor::RightsMetadataDS.from_xml(rights_metadata_xml))
  end
  let(:mapped_structural_props) { Cocina::FromFedora::DroStructural.props(fedora_item_mock, type: dro_type) }
  let(:roundtrip_content_md_xml) { defined?(roundtrip_content_metadata_xml) ? roundtrip_content_metadata_xml : content_metadata_xml }
  let(:normalized_orig_content_xml) do
    # the starting contentMetadata is normalized to address discrepancies found against contentMetadata roundtripped
    #  to data store (Fedora) and back, per Andrew's specifications.
    #  E.g., removing id attribute on resource nodes
    norm_b4 = Cocina::Normalizers::ContentMetadataNormalizer.normalize(druid: full_druid, content_ng_xml: Nokogiri::XML(content_metadata_xml)).to_xml
    Cocina::Normalizers::ContentMetadataNormalizer.normalize_roundtrip(content_ng_xml: Nokogiri::XML(norm_b4)).to_xml
  end
  let(:new_file_set_uuid) { 'http://cocina.sul.stanford.edu/fileSet/(new_uuid)' }
  let(:new_file_uuid) { 'http://cocina.sul.stanford.edu/file/(new_uuid)' }

  before do
    content_metadata_ds = Dor::ContentMetadataDS.from_xml(content_metadata_xml)
    allow(fedora_item).to receive(:contentMetadata).and_return(content_metadata_ds)
    allow(Cocina::IdGenerator).to receive(:generate_fileset_id).and_return(new_file_set_uuid)
    allow(Cocina::IdGenerator).to receive(:generate_file_id).and_return(new_file_uuid)
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina DROStructural' do
      expect { Cocina::Models::DROStructural.new(cocina_structural_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_structural_props).to be_deep_equal(cocina_structural_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:mapped_structural) { Cocina::Models::DROStructural.new(mapped_structural_props) }
    let(:cocina_dro_hash) do
      {
        type: dro_type,
        externalIdentifier: full_druid,
        label: '',
        version: version,
        access: {},
        description: { title: [{ value: 'contentMetadata <-> cocina structural testing' }] },
        administrative: { hasAdminPolicy: 'druid:nn000nn0000' },
        identification: {},
        structural: mapped_structural_props
      }
    end
    let(:cocina_dro) { Cocina::Models::DRO.new(cocina_dro_hash) }
    let(:roundtripped_content_metadata_xml) { Cocina::ToFedora::ContentMetadataGenerator.generate(druid: full_druid, object: cocina_dro) }

    it 'contentMetadata roundtrips thru cocina model to provided expected contentMetadata.xml' do
      # FIXME: this is not working due to sequence attribute on resource tag, see https://github.com/sul-dlss/dor-services-app/issues/2841
      expect(roundtripped_content_metadata_xml).to be_equivalent_to(roundtrip_content_md_xml)
    end

    it 'contentMetadata roundtrips thru cocina model to normalized original contentMetadata.xml' do
      expect(roundtripped_content_metadata_xml).to be_equivalent_to(normalized_orig_content_xml)
    end
  end

  # context 'when mapping from roundtrip Fedora to (roundtrip) Cocina' do
  #   let(:roundtrip_fedora_item) { Dor::Item.new }
  #   let(:roundtrip_access_props) { Cocina::FromFedora::DROAccess.props(roundtrip_fedora_item.rightsMetadata, roundtrip_fedora_item.embargoMetadata) }
  #   let(:roundtrip_structural_props) { Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: dro_type) }
  #
  #   before do
  #     roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_metadata_xml)
  #     allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
  #     if defined?(embargo_xml)
  #       embargo_metadata_ds = Dor::EmbargoMetadataDS.from_xml(embargo_xml)
  #       allow(roundtrip_fedora_item).to receive(:embargoMetadata).and_return(embargo_metadata_ds)
  #     end
  #     roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(roundtrip_content_metadata_xml)
  #     allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
  #   end
  #
  #   it 'roundtrip Fedora maps to expected Cocina object props' do
  #     expect(roundtrip_structural_props).to be_deep_equal(cocina_structural_props)
  #   end
  # end

  # context 'when mapping from normalized orig Fedora content_metadata_xml to (roundtrip) Cocina' do
  #   let(:roundtrip_fedora_item) { Dor::Item.new }
  #   let(:roundtrip_access_props) { Cocina::FromFedora::DROAccess.props(roundtrip_fedora_item.rightsMetadata, roundtrip_fedora_item.embargoMetadata) }
  #   let(:roundtrip_structural_props) { Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: Cocina::Models::Vocab.book) }
  #
  #   before do
  #     roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(normalized_orig_rights_xml)
  #     allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
  #     if defined?(embargo_xml)
  #       embargo_metadata_ds = Dor::EmbargoMetadataDS.from_xml(embargo_xml)
  #       allow(roundtrip_fedora_item).to receive(:embargoMetadata).and_return(embargo_metadata_ds)
  #     end
  #     roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(roundtrip_content_metadata_xml)
  #     allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
  #   end
  #
  #   it 'normalized Fedora rights_xml maps to expected Cocina object props' do
  #     expect(roundtrip_access_props).to be_deep_equal(cocina_access_props)
  #     expect(roundtrip_structural_props).to be_deep_equal(cocina_structural_props)
  #   end
  # end
end

RSpec.describe 'Fedora item contentMetadata <--> Cocina DRO structural mappings' do
  describe 'book Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.book }

    context 'with newark newspaper collection object' do
      before do
        allow(AdministrativeTags).to receive(:content_type).with(pid: 'druid:bb000dy4885').and_return(['Book (ltr)'])
      end

      it_behaves_like 'DRO Structural Fedora Cocina mapping' do
        let(:bare_druid) { 'bb000dy4885' }
        let(:version) { 1 }
        let(:collection_ids) { [] }
        let(:rights_metadata_xml) do
          <<~XML
            <rightsMetadata objectId="druid:#{bare_druid}">
              <access type="discover">
                <machine>
                  <dark/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end
        let(:content_metadata_xml) do
          <<~XML
            <contentMetadata objectId="bb000dy4885" type="book">
              <resource id="bb000dy4885_1" sequence="1" type="page">
                <label>Page 1</label>
                <file id="zhxx_19510610_0001.jp2" preserve="yes" shelve="no" publish="no" size="7511960" mimetype="image/jp2">
                  <checksum type="md5">954902028de6c76ceef9cfa486fcea67</checksum>
                  <checksum type="sha1">3c3702b627bd48ddb5e71044a4fd8276c20b5a50</checksum>
                  <imageData width="6868" height="8764"/>
                </file>
                <file id="zhxx_19510610_0001.pdf" preserve="yes" shelve="no" publish="no" size="2166905" mimetype="application/pdf">
                  <checksum type="md5">b80519ed02ecd839573631f2be6383ef</checksum>
                  <checksum type="sha1">bc0831fc4483aca89f37ca7fe1170492529b9d16</checksum>
                </file>
                <file id="zhxx_19510610_0001.tiff" preserve="yes" shelve="no" publish="no" size="180644001" mimetype="image/tiff">
                  <checksum type="md5">70eb736439b0b5fe9b4bad94f485d2fa</checksum>
                  <checksum type="sha1">5033a43dd35355019d365aef6972f09b135fe5d3</checksum>
                  <imageData width="6868" height="8764"/>
                </file>
                <file id="zhxx_19510610_0001.xml" preserve="yes" shelve="no" publish="no" size="560697" mimetype="application/xml">
                  <checksum type="md5">d49630c1a8c1b4535d9b00724454368d</checksum>
                  <checksum type="sha1">e07c09daf88b949ecdaaa0d5455765b5596794c3</checksum>
                </file>
              </resource>
              <resource id="bb000dy4885_2" sequence="2" type="object">
                <label>Object 1</label>
                <file id="zhxx_19510610_mets.xml" preserve="yes" shelve="no" publish="no" size="17834" mimetype="application/xml">
                  <checksum type="md5">8e69008fee1ae18c7d9ca0bb1832c608</checksum>
                  <checksum type="sha1">c9b41650c8f6f595948e481a7a87606600fa05c5</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        end
        let(:cocina_structural_props) do
          # "type": "http://cocina.sul.stanford.edu/models/book.jsonld",
          {
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/page.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Page 1',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'zhxx_19510610_0001.jp2',
                      filename: 'zhxx_19510610_0001.jp2',
                      size: 7_511_960,
                      version: version,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '3c3702b627bd48ddb5e71044a4fd8276c20b5a50'
                        },
                        {
                          type: 'md5',
                          digest: '954902028de6c76ceef9cfa486fcea67'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      },
                      presentation: {
                        height: 8764,
                        width: 6868
                      }
                    },
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'zhxx_19510610_0001.pdf',
                      filename: 'zhxx_19510610_0001.pdf',
                      size: 2_166_905,
                      version: version,
                      hasMimeType: 'application/pdf',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'bc0831fc4483aca89f37ca7fe1170492529b9d16'
                        },
                        {
                          type: 'md5',
                          digest: 'b80519ed02ecd839573631f2be6383ef'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    },
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'zhxx_19510610_0001.tiff',
                      filename: 'zhxx_19510610_0001.tiff',
                      size: 180_644_001,
                      version: version,
                      hasMimeType: 'image/tiff',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '5033a43dd35355019d365aef6972f09b135fe5d3'
                        },
                        {
                          type: 'md5',
                          digest: '70eb736439b0b5fe9b4bad94f485d2fa'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      },
                      presentation: {
                        height: 8764,
                        width: 6868
                      }
                    },
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'zhxx_19510610_0001.xml',
                      filename: 'zhxx_19510610_0001.xml',
                      size: 560697,
                      version: version,
                      hasMimeType: 'application/xml',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'e07c09daf88b949ecdaaa0d5455765b5596794c3'
                        },
                        {
                          type: 'md5',
                          digest: 'd49630c1a8c1b4535d9b00724454368d'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Object 1',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'zhxx_19510610_mets.xml',
                      filename: 'zhxx_19510610_mets.xml',
                      size: 17834,
                      version: version,
                      hasMimeType: 'application/xml',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'c9b41650c8f6f595948e481a7a87606600fa05c5'
                        },
                        {
                          type: 'md5',
                          digest: '8e69008fee1ae18c7d9ca0bb1832c608'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              }
            ],
            hasMemberOrders: [
              {
                viewingDirection: 'left-to-right'
              }
            ]
          }
        end
      end
    end

    context 'with google book: with ltr specified, zipped images' do
      it_behaves_like 'DRO Structural Fedora Cocina mapping' do
        let(:bare_druid) { 'bb000sh0504' }
        let(:version) { 1 }
        let(:collection_ids) { ['druid:yh583fk3400'] }
        let(:rights_metadata_xml) do
          <<~XML
            <rightsMetadata objectId="druid:#{bare_druid}">
              <access type="discover">
                <machine>
                  <world/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end
        let(:content_metadata_xml) do
          <<~XML
            <contentMetadata objectId="druid:bb000sh0504" type="book">
              <bookData readingOrder="ltr"/>
              <resource id="bb000sh0504_1" sequence="1" type="object">
                <label>hOCR</label>
                <file id="36105009072476-gb-hocr.zip" mimetype="application/zip" size="9649201" publish="no" shelve="no" preserve="yes">
                  <checksum type="sha1">7e5cac88ebe9c541e519cd8263226c471b963cff</checksum>
                  <checksum type="md5">8913471e6155801e9a6af2c0f2e4c4fe</checksum>
                </file>
              </resource>
              <resource id="bb000sh0504_2" sequence="2" type="object">
                <label>Page images</label>
                <file id="36105009072476-gb-jp2.zip" mimetype="application/zip" size="42288285" publish="no" shelve="no" preserve="yes">
                  <checksum type="sha1">4911d83eb4e36c562f6e8fcb255f4d08957ba5b0</checksum>
                  <checksum type="md5">1650e0db67f49f1f3a3971d3b53c9e4b</checksum>
                </file>
              </resource>
              <resource id="bb000sh0504_3" sequence="3" type="object">
                <label>Plain text OCR</label>
                <file id="36105009072476-gb-txt.zip" mimetype="application/zip" size="430944" publish="no" shelve="no" preserve="yes">
                  <checksum type="sha1">b28348f731789d415a48f8df6dceb4140886ddd1</checksum>
                  <checksum type="md5">d644e37b5779d3f77940ada986682885</checksum>
                </file>
              </resource>
              <resource id="bb000sh0504_4" sequence="4" type="object">
                <label>Google Books METS XML</label>
                <file id="STANFORD_36105009072476.xml" mimetype="application/xml" size="471008" publish="no" shelve="no" preserve="yes">
                  <checksum type="sha1">d51caa80775cad35f1a7c3cb8a60d90f532186d1</checksum>
                  <checksum type="md5">fc390df1ac68dfa8e10c57cdac16047b</checksum>
                </file>
              </resource>
              <resource id="bb000sh0504_5" sequence="5" type="object">
                <label>Google Books file checksums</label>
                <file id="checksum.md5" mimetype="application/octet-stream" size="29030" publish="no" shelve="no" preserve="yes">
                  <checksum type="sha1">1b1af7b2d45d020191206e2b8b77ee4acf205c9b</checksum>
                  <checksum type="md5">0c3fb9a7d4973bedd018be7e570f260e</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        end
        let(:cocina_structural_props) do
          {
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'hOCR',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: '36105009072476-gb-hocr.zip',
                      filename: '36105009072476-gb-hocr.zip',
                      size: 9_649_201,
                      version: version,
                      hasMimeType: 'application/zip',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '7e5cac88ebe9c541e519cd8263226c471b963cff'
                        },
                        {
                          type: 'md5',
                          digest: '8913471e6155801e9a6af2c0f2e4c4fe'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Page images',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: '36105009072476-gb-jp2.zip',
                      filename: '36105009072476-gb-jp2.zip',
                      size: 42_288_285,
                      version: version,
                      hasMimeType: 'application/zip',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '4911d83eb4e36c562f6e8fcb255f4d08957ba5b0'
                        },
                        {
                          type: 'md5',
                          digest: '1650e0db67f49f1f3a3971d3b53c9e4b'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Plain text OCR',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: '36105009072476-gb-txt.zip',
                      filename: '36105009072476-gb-txt.zip',
                      size: 430944,
                      version: version,
                      hasMimeType: 'application/zip',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'b28348f731789d415a48f8df6dceb4140886ddd1'
                        },
                        {
                          type: 'md5',
                          digest: 'd644e37b5779d3f77940ada986682885'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Google Books METS XML',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'STANFORD_36105009072476.xml',
                      filename: 'STANFORD_36105009072476.xml',
                      size: 471008,
                      version: version,
                      hasMimeType: 'application/xml',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'd51caa80775cad35f1a7c3cb8a60d90f532186d1'
                        },
                        {
                          type: 'md5',
                          digest: 'fc390df1ac68dfa8e10c57cdac16047b'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/object.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: 'Google Books file checksums',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'checksum.md5',
                      filename: 'checksum.md5',
                      size: 29030,
                      version: version,
                      hasMimeType: 'application/octet-stream',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '1b1af7b2d45d020191206e2b8b77ee4acf205c9b'
                        },
                        {
                          type: 'md5',
                          digest: '0c3fb9a7d4973bedd018be7e570f260e'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              }
            ],
            hasMemberOrders: [
              {
                viewingDirection: 'left-to-right'
              }
            ],
            isMemberOf: [
              'druid:yh583fk3400'
            ]
          }
        end
      end
    end

    context 'with project phoenix book: with ltr specified, zipped images' do
      it_behaves_like 'DRO Structural Fedora Cocina mapping' do
        let(:bare_druid) { 'bb001mf4282' }
        let(:version) { 1 }
        let(:collection_ids) { [] }
        let(:rights_metadata_xml) do
          <<~XML
            <rightsMetadata objectId="druid:#{bare_druid}">
              <access type="discover">
                <machine>
                  <dark/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end
        let(:content_metadata_xml) do
          <<~XML
            <contentMetadata type="book" objectId="druid:bb001mf4282">
              <resource type="page" sequence="1" id="page1">
                <attr name="googlePageTag">FRONT_COVER IMAGE_ON_PAGE IMPLICIT_PAGE_NUMBER</attr>
                <file shelve="no" deliver="no" preserve="yes" format="JPEG2000" size="473994" mimetype="image/jp2" id="00000001.jp2">
                  <imageData height="2176" width="1456"/>
                  <checksum type="SHA-1">1f2a99268c56a8ba75a9d4ec4398651266139f14</checksum>
                  <checksum type="MD5">63e2ea5d798c1c2d5b0f6099ec11810d</checksum>
                </file>
                <file dataType="hocr" shelve="yes" deliver="no" preserve="yes" format="HTML" size="847" mimetype="text/html" id="00000001.html">
                  <checksum type="SHA-1">9882062fdea59f4fbc4594ad0a405a104165d9d2</checksum>
                  <checksum type="MD5">317e9a14d4a9fb874919154ffaa163a8</checksum>
                </file>
              </resource>
              <resource type="METS" id="googleMETS">
                <file shelve="no" deliver="no" preserve="yes" format="TEXT" size="286705" mimetype="application/xml" id="googleMETS.xml">
                  <checksum type="SHA-1">bc22b16be10d742ccde9be81bf516c749942dbb4</checksum>
                  <checksum type="MD5">47f5e89bf771cc27496b98908ea267f5</checksum>
                </file>
              </resource>
              <resource type="metadata" id="technicalMetadata">
                <file shelve="no" deliver="no" preserve="yes" format="TEXT" size="1019771" mimetype="application/xml" id="technicalMetadata.xml">
                  <checksum type="SHA-1">69148bf0022a5eaf6a5de63904ccb890a69dd151</checksum>
                  <checksum type="MD5">449e049328f62e199345a43adb721a12</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        end
        let(:cocina_structural_props) do
          {
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/page.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: '',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: '00000001.jp2',
                      filename: '00000001.jp2',
                      size: 473994,
                      version: version,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '1f2a99268c56a8ba75a9d4ec4398651266139f14'
                        },
                        {
                          type: 'md5',
                          digest: '63e2ea5d798c1c2d5b0f6099ec11810d'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      },
                      presentation: {
                        height: 2176,
                        width: 1456
                      }
                    },
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: '00000001.html',
                      filename: '00000001.html',
                      size: 847,
                      version: version,
                      hasMimeType: 'text/html',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '9882062fdea59f4fbc4594ad0a405a104165d9d2'
                        },
                        {
                          type: 'md5',
                          digest: '317e9a14d4a9fb874919154ffaa163a8'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: true
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: '',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'googleMETS.xml',
                      filename: 'googleMETS.xml',
                      size: 286705,
                      version: version,
                      hasMimeType: 'application/xml',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'bc22b16be10d742ccde9be81bf516c749942dbb4'
                        },
                        {
                          type: 'md5',
                          digest: '47f5e89bf771cc27496b98908ea267f5'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: '',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'technicalMetadata.xml',
                      filename: 'technicalMetadata.xml',
                      size: 1_019_771,
                      version: version,
                      hasMimeType: 'application/xml',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: '69148bf0022a5eaf6a5de63904ccb890a69dd151'
                        },
                        {
                          type: 'md5',
                          digest: '449e049328f62e199345a43adb721a12'
                        }
                      ],
                      access: {
                        access: 'dark',
                        download: 'none'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: false
                      }
                    }
                  ]
                }
              }
            ]
          }
        end
      end
    end
  end

  describe 'document Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.document }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'file Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.object }

    context 'with recent ETD but before ETD rewrite' do
      it_behaves_like 'DRO Structural Fedora Cocina mapping' do
        # xit 'to be implemented:  this does not roundtrip cleanly' do
        let(:bare_druid) { 'bb164pj1759' }
        let(:collection_ids) { ['druid:ct692vv3660'] } # from RELS-EXT
        let(:version) { 3 }
        let(:rights_metadata_xml) do
          <<~XML
            <rightsMetadata objectId="druid:#{bare_druid}">
              <access type="discover">
                <machine>
                  <world/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end
        let(:content_metadata_xml) do
          <<~XML
            <contentMetadata type="file" objectId="druid:bb164pj1759">
              <resource id="bb164pj1759_1" type="main-original">
                <attr name="label">Body of dissertation (as submitted)</attr>
                <file id="e-thesis submitted.pdf" mimetype="application/pdf" size="4900178" shelve="yes" publish="no" preserve="yes">
                  <checksum type="md5">0bdfb9d688f96c1cd8cf7d2c51ea1e40</checksum>
                  <checksum type="sha1">bf515ab4babd8a500b278b2c4bf634f395b94cce</checksum>
                </file>
              </resource>
              <resource id="bb164pj1759_2" type="main-augmented" objectId="druid:yx117zy0511">
                <attr name="label">Body of dissertation</attr>
                <file id="e-thesis submitted-augmented.pdf" mimetype="application/pdf" size="4792366" shelve="yes" publish="yes" preserve="yes">
                  <checksum type="md5">0b2b4e8cf1bbb30e8a266b95965ed0d1</checksum>
                  <checksum type="sha1">eeaea05d7f85519f26665fc51e522d47281e0ba7</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        end
        # FIXME: sequence numbers have problematic mapping rules: https://github.com/sul-dlss/dor-services-app/issues/2841
        # FIXME:  should these nodes just become label nodes?
        # <attr name="label">Body of dissertation (as submitted)</attr>
        # <attr name="label">Body of dissertation</attr>
        let(:roundtrip_content_metadata_xml) do
          <<~XML
            <contentMetadata type="file" objectId="druid:bb164pj1759">
              <resource id="http://cocina.sul.stanford.edu/fileSet/(new_uuid)" sequence="1" type="main-original">
                <file id="e-thesis submitted.pdf" mimetype="application/pdf" size="4900178" shelve="yes" publish="no" preserve="yes">
                  <checksum type="md5">0bdfb9d688f96c1cd8cf7d2c51ea1e40</checksum>
                  <checksum type="sha1">bf515ab4babd8a500b278b2c4bf634f395b94cce</checksum>
                </file>
              </resource>
              <resource id="http://cocina.sul.stanford.edu/fileSet/(new_uuid)" sequence="2" type="main-augmented">
                <file id="e-thesis submitted-augmented.pdf" mimetype="application/pdf" size="4792366" shelve="yes" publish="yes" preserve="yes">
                  <checksum type="md5">0b2b4e8cf1bbb30e8a266b95965ed0d1</checksum>
                  <checksum type="sha1">eeaea05d7f85519f26665fc51e522d47281e0ba7</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        end
        let(:cocina_structural_props) do
          {
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/main-original.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: '',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'e-thesis submitted.pdf',
                      filename: 'e-thesis submitted.pdf',
                      size: 4_900_178,
                      version: version,
                      hasMimeType: 'application/pdf',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'bf515ab4babd8a500b278b2c4bf634f395b94cce'
                        },
                        {
                          type: 'md5',
                          digest: '0bdfb9d688f96c1cd8cf7d2c51ea1e40'
                        }
                      ],
                      access: {
                        access: 'world',
                        download: 'world'
                      },
                      administrative: {
                        publish: false,
                        sdrPreserve: true,
                        shelve: true
                      }
                    }
                  ]
                }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/main-augmented.jsonld',
                externalIdentifier: new_file_set_uuid,
                label: '',
                version: version,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: new_file_uuid,
                      label: 'e-thesis submitted-augmented.pdf',
                      filename: 'e-thesis submitted-augmented.pdf',
                      size: 4_792_366,
                      version: version,
                      hasMimeType: 'application/pdf',
                      hasMessageDigests: [
                        {
                          type: 'sha1',
                          digest: 'eeaea05d7f85519f26665fc51e522d47281e0ba7'
                        },
                        {
                          type: 'md5',
                          digest: '0b2b4e8cf1bbb30e8a266b95965ed0d1'
                        }
                      ],
                      access: {
                        access: 'world',
                        download: 'world'
                      },
                      administrative: {
                        publish: true,
                        sdrPreserve: true,
                        shelve: true
                      }
                    }
                  ]
                }
              }
            ],
            isMemberOf:
              [
                collection_ids.join(',')
              ]
          }
        end
      end
    end

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'geo Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.geo }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'image Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.image }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'map Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.map }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'media Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.media }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe 'webarchive-seed Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.webarchive_seed }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end

  describe '3d Argo object type' do
    let(:dro_type) { Cocina::Models::Vocab.three_dimensional }

    xit 'to be implemented: get a recent object of this type and an object of this type from before 2015 and call shared examples for each'
  end
end
