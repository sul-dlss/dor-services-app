# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fedora item content metadata <--> Cocina DRO structural mappings for virtual objects' do
  context 'when a typical content metadata' do
    # From bc426tg5901
    it_behaves_like 'DRO Structural Fedora Cocina mapping' do
      before do
        allow(CocinaObjectStore).to receive(:find).with('druid:gj047zn0886').and_return(child1)
        allow(CocinaObjectStore).to receive(:find).with('druid:tm207xk5096').and_return(child2)
      end

      let(:child1) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:gj047zn0886',
          version: 1,
          label: 'Constituent 1',
          access: {},
          administrative: {
            hasAdminPolicy: 'druid:bx911tp9024'
          },
          description: {
            title: [{ value: 'Number 1' }],
            purl: 'https://example.com'
          },
          type: Cocina::Models::ObjectType.image,
          structural: child_structural1,
          identification: {}
        )
      end

      let(:child2) do
        Cocina::Models::DRO.new(
          externalIdentifier: 'druid:tm207xk5096',
          version: 1,
          label: 'Constituent 2',
          access: {},
          administrative: {
            hasAdminPolicy: 'druid:bx911tp9024'
          },
          description: {
            title: [{ value: 'Number 2' }],
            purl: 'https://example.com'
          },
          type: Cocina::Models::ObjectType.image,
          structural: child_structural2,
          identification: {}
        )
      end
      let(:child_structural1) do
        Cocina::Models::DROStructural.new({
                                            contains: [{
                                              type: Cocina::Models::FileSetType.image,
                                              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/13c6b4ac-70d8-4389-beef-a1768f37bb68',
                                              label: 'Image 1',
                                              version: 6,
                                              structural: {
                                                contains: [{
                                                  type: Cocina::Models::ObjectType.file,
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/bd5bb755-ae47-4309-bfa9-5ac7b57a27d1',
                                                  label: 'PC0170_s1_B_0539.tif',
                                                  filename: 'PC0170_s1_B_0539.tif',
                                                  size: 182_111_284,
                                                  version: 6,
                                                  hasMimeType: 'image/tiff',
                                                  hasMessageDigests: [{
                                                    type: 'sha1',
                                                    digest: 'a262edfd2fc4d1349c57a341fdfcfc83fce928fa'
                                                  }, {
                                                    type: 'md5',
                                                    digest: 'd1114dbe04e0b6282544db5c989d5181'
                                                  }],
                                                  access: {
                                                    view: 'world',
                                                    download: 'world'
                                                  },
                                                  administrative: {
                                                    publish: false,
                                                    sdrPreserve: true,
                                                    shelve: false
                                                  },
                                                  presentation: {
                                                    height: 6726,
                                                    width: 4512
                                                  }
                                                }, {
                                                  type: Cocina::Models::ObjectType.file,
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/8d9960c8-7249-422c-8cfd-c486edeb47ba',
                                                  label: 'PC0170_s1_B_0539.jp2',
                                                  filename: 'PC0170_s1_B_0539.jp2',
                                                  size: 5_730_422,
                                                  version: 6,
                                                  hasMimeType: 'image/jp2',
                                                  hasMessageDigests: [{
                                                    type: 'sha1',
                                                    digest: '9877ea2803b71aaeb45405367e5323730ec0584d'
                                                  }, {
                                                    type: 'md5',
                                                    digest: '68a48dc1a2917b9a52a4cbec4a691a9d'
                                                  }],
                                                  access: {
                                                    view: 'world',
                                                    download: 'world'
                                                  },
                                                  administrative: {
                                                    publish: true,
                                                    sdrPreserve: false,
                                                    shelve: true
                                                  },
                                                  presentation: {
                                                    height: 6726,
                                                    width: 4512
                                                  }
                                                }]
                                              }
                                            }],
                                            hasMemberOrders: [],
                                            isMemberOf: ['druid:gh795jd5965']
                                          })
      end

      let(:child_structural2) do
        Cocina::Models::DROStructural.new({
                                            contains: [{
                                              type: Cocina::Models::FileSetType.image,
                                              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/725a5c09-8689-47f5-a80b-d39d5f4d0f7b',
                                              label: 'Image 1',
                                              version: 6,
                                              structural: {
                                                contains: [{
                                                  type: Cocina::Models::ObjectType.file,
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/f477946d-9f73-44f7-90de-2ca448995701',
                                                  label: 'PC0170_s1_B_0540.tif',
                                                  filename: 'PC0170_s1_B_0540.tif',
                                                  size: 181_303_012,
                                                  version: 6,
                                                  hasMimeType: 'image/tiff',
                                                  hasMessageDigests: [{
                                                    type: 'sha1',
                                                    digest: '3803d4c9da953d970cc2557880172d58055f5aaf'
                                                  }, {
                                                    type: 'md5',
                                                    digest: 'a988f5b9a57a0f3a5ae68e000cca01e4'
                                                  }],
                                                  access: {
                                                    view: 'world',
                                                    download: 'world'
                                                  },
                                                  administrative: {
                                                    publish: false,
                                                    sdrPreserve: true,
                                                    shelve: false
                                                  },
                                                  presentation: {
                                                    height: 6714,
                                                    width: 4500
                                                  }
                                                }, {
                                                  type: Cocina::Models::ObjectType.file,
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/86d5bc2c-e5d5-44aa-80a9-8a2fb5b4584a',
                                                  label: 'PC0170_s1_B_0540.jp2',
                                                  filename: 'PC0170_s1_B_0540.jp2',
                                                  size: 5_705_291,
                                                  version: 6,
                                                  hasMimeType: 'image/jp2',
                                                  hasMessageDigests: [{
                                                    type: 'sha1',
                                                    digest: 'eaabb02b7fb4bd743c60305e51b43904a85a1a3a'
                                                  }, {
                                                    type: 'md5',
                                                    digest: '5f163c001ddb2eed8639f749c1d07f09'
                                                  }],
                                                  access: {
                                                    view: 'world',
                                                    download: 'world'
                                                  },
                                                  administrative: {
                                                    publish: true,
                                                    sdrPreserve: false,
                                                    shelve: true
                                                  },
                                                  presentation: {
                                                    height: 6714,
                                                    width: 4500
                                                  }
                                                }]
                                              }
                                            },
                                                       {
                                                         type: Cocina::Models::FileSetType.image,
                                                         externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/725a5c09-8689-47f5-a80b-d39d5f4d0f7c',
                                                         label: 'Image 2',
                                                         version: 6,
                                                         structural: {
                                                           contains: [{
                                                             type: Cocina::Models::ObjectType.file,
                                                             externalIdentifier: 'https://cocina.sul.stanford.edu/file/f477946d-9f73-44f7-90de-2ca448995702',
                                                             label: 'PC0170_s1_B_0540_2.tif',
                                                             filename: 'PC0170_s1_B_0540_2.tif',
                                                             size: 181_303_012,
                                                             version: 6,
                                                             hasMimeType: 'image/tiff',
                                                             hasMessageDigests: [{
                                                               type: 'sha1',
                                                               digest: '3803d4c9da953d970cc2557880172d58055f5aaf'
                                                             }, {
                                                               type: 'md5',
                                                               digest: 'a988f5b9a57a0f3a5ae68e000cca01e4'
                                                             }],
                                                             access: {
                                                               view: 'world',
                                                               download: 'world'
                                                             },
                                                             administrative: {
                                                               publish: false,
                                                               sdrPreserve: true,
                                                               shelve: false
                                                             },
                                                             presentation: {
                                                               height: 6714,
                                                               width: 4500
                                                             }
                                                           }, {
                                                             type: Cocina::Models::ObjectType.file,
                                                             externalIdentifier: 'https://cocina.sul.stanford.edu/file/86d5bc2c-e5d5-44aa-80a9-8a2fb5b4584b',
                                                             label: 'PC0170_s1_B_0540_2.jp2',
                                                             filename: 'PC0170_s1_B_0540_2.jp2',
                                                             size: 5_705_291,
                                                             version: 6,
                                                             hasMimeType: 'image/jp2',
                                                             hasMessageDigests: [{
                                                               type: 'sha1',
                                                               digest: 'eaabb02b7fb4bd743c60305e51b43904a85a1a3a'
                                                             }, {
                                                               type: 'md5',
                                                               digest: '5f163c001ddb2eed8639f749c1d07f09'
                                                             }],
                                                             access: {
                                                               view: 'world',
                                                               download: 'world'
                                                             },
                                                             administrative: {
                                                               publish: true,
                                                               sdrPreserve: false,
                                                               shelve: true
                                                             },
                                                             presentation: {
                                                               height: 6714,
                                                               width: 4500
                                                             }
                                                           }]
                                                         }
                                                       }],
                                            hasMemberOrders: [],
                                            isMemberOf: ['druid:gh795jd5965']
                                          })
      end

      let(:object_type) { Cocina::Models::ObjectType.image }

      let(:content_xml) do
        <<~XML
          <contentMetadata objectId="#{druid}" type="image">
            <resource id="bc426tg5901_1" sequence="1" type="image">
              <externalFile fileId="PC0170_s1_B_0539.jp2" mimetype="image/jp2" objectId="druid:gj047zn0886" resourceId="gj047zn0886_1"/>
              <relationship objectId="druid:gj047zn0886" type="alsoAvailableAs"/>
            </resource>
            <resource id="bc426tg5901_2" sequence="2" type="image">
              <externalFile fileId="PC0170_s1_B_0540.jp2" mimetype="image/jp2" objectId="druid:tm207xk5096" resourceId="tm207xk5096_1"/>
              <relationship objectId="druid:tm207xk5096" type="alsoAvailableAs"/>
            </resource>
            <resource id="bc426tg5901_3" sequence="3" type="image">
              <externalFile fileId="PC0170_s1_B_0540_2.jp2" mimetype="image/jp2" objectId="druid:tm207xk5096" resourceId="tm207xk5096_1"/>
              <relationship objectId="druid:tm207xk5096" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
        XML
      end

      let(:roundtrip_content_xml) do
        <<~XML
          <contentMetadata objectId="#{druid}" type="image">
            <resource id="bc426tg5901_1" sequence="1" type="image">
              <externalFile fileId="PC0170_s1_B_0539.jp2" mimetype="image/jp2" objectId="druid:gj047zn0886" resourceId="https://cocina.sul.stanford.edu/fileSet/13c6b4ac-70d8-4389-beef-a1768f37bb68"/>
              <relationship objectId="druid:gj047zn0886" type="alsoAvailableAs"/>
            </resource>
            <resource id="bc426tg5901_2" sequence="2" type="image">
              <externalFile fileId="PC0170_s1_B_0540.jp2" mimetype="image/jp2" objectId="druid:tm207xk5096" resourceId="https://cocina.sul.stanford.edu/fileSet/725a5c09-8689-47f5-a80b-d39d5f4d0f7b"/>
              <relationship objectId="druid:tm207xk5096" type="alsoAvailableAs"/>
            </resource>
            <resource id="bc426tg5901_3" sequence="3" type="image">
              <externalFile fileId="PC0170_s1_B_0540_2.jp2" mimetype="image/jp2" objectId="druid:tm207xk5096" resourceId="tm207xk5096_1"/>
              <relationship objectId="druid:tm207xk5096" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
        XML
      end

      let(:cocina_structural_props) do
        {
          hasMemberOrders: [
            {
              members: [
                'druid:gj047zn0886',
                'druid:tm207xk5096'
              ]
            }
          ]
        }
      end
    end
  end
end
