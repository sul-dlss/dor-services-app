# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalStacksDiffer do
  let(:druid) { 'druid:hj185xx2222' }

  let(:cocina_object) do
    build(:dro, id: druid).new(access: { view: 'world' }, structural: {
                                 contains: [
                                   {
                                     type: Cocina::Models::FileSetType.file.to_s,
                                     externalIdentifier: 'hj185xx2222_1',
                                     label: 'Image 1',
                                     version: 3,
                                     structural: {
                                       contains: [
                                         {
                                           type: Cocina::Models::ObjectType.file.to_s,
                                           externalIdentifier: 'druid:hj185xx2222/not_shelved.jpg',
                                           label: 'not shelved',
                                           filename: 'not_shelved.jpg',
                                           size: 29_634,
                                           version: 3,
                                           hasMimeType: 'image/jpeg',
                                           hasMessageDigests: [
                                             {
                                               type: 'sha1',
                                               digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                             },
                                             {
                                               type: 'md5',
                                               digest: '3e9498107f73ff827e718d5c743f8813'
                                             }
                                           ],
                                           access: {
                                             view: 'dark',
                                             download: 'none'
                                           },
                                           administrative: {
                                             sdrPreserve: true,
                                             shelve: false,
                                             publish: false
                                           }
                                         },
                                         {
                                           type: Cocina::Models::ObjectType.file.to_s,
                                           externalIdentifier: 'druid:hj185xx2222/not_on_shelves.jpg',
                                           label: 'not on shelves',
                                           filename: 'not_on_shelves.jpg',
                                           size: 29_634,
                                           version: 3,
                                           hasMimeType: 'image/jpeg',
                                           hasMessageDigests: [
                                             {
                                               type: 'sha1',
                                               digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                             },
                                             {
                                               type: 'md5',
                                               digest: '3e9498107f73ff827e718d5c743f8813'
                                             }
                                           ],
                                           access: {
                                             view: 'world',
                                             download: 'world'
                                           },
                                           administrative: {
                                             sdrPreserve: true,
                                             shelve: true,
                                             publish: true
                                           }
                                         },
                                         {
                                           type: Cocina::Models::ObjectType.file.to_s,
                                           externalIdentifier: 'druid:hj185xx2222/changed_on_shelves.jpg',
                                           label: 'changed on shelves',
                                           filename: 'changed_on_shelves.jpg',
                                           size: 29_634,
                                           version: 3,
                                           hasMimeType: 'image/jpeg',
                                           hasMessageDigests: [
                                             {
                                               type: 'sha1',
                                               digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                             },
                                             {
                                               type: 'md5',
                                               digest: '3e9498107f73ff827e718d5c743f8813'
                                             }
                                           ],
                                           access: {
                                             view: 'world',
                                             download: 'world'
                                           },
                                           administrative: {
                                             sdrPreserve: true,
                                             shelve: true,
                                             publish: true
                                           }
                                         },
                                         {
                                           type: Cocina::Models::ObjectType.file.to_s,
                                           externalIdentifier: 'druid:hj185xx2222/same_on_shelves.jpg',
                                           label: 'same on shelves',
                                           filename: 'same_on_shelves.jpg',
                                           size: 29_634,
                                           version: 3,
                                           hasMimeType: 'image/jpeg',
                                           hasMessageDigests: [
                                             {
                                               type: 'sha1',
                                               digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                             },
                                             {
                                               type: 'md5',
                                               digest: '3e9498107f73ff827e718d5c743f8813'
                                             }
                                           ],
                                           access: {
                                             view: 'world',
                                             download: 'world'
                                           },
                                           administrative: {
                                             sdrPreserve: true,
                                             shelve: true,
                                             publish: true
                                           }
                                         }
                                       ]
                                     }
                                   }
                                 ],
                                 isMemberOf: [
                                   'druid:bc778pm9866'
                                 ]
                               })
  end

  let(:purl_cocina_object) do
    cocina_object.new(structural: {
                        contains: [
                          {
                            type: Cocina::Models::FileSetType.file.to_s,
                            externalIdentifier: 'hj185xx2222_1',
                            label: 'Image 1',
                            version: 3,
                            structural: {
                              contains: [
                                {
                                  type: Cocina::Models::ObjectType.file.to_s,
                                  externalIdentifier: 'druid:hj185xx2222/only_on_shelves.jpg',
                                  label: 'only on shelves',
                                  filename: 'only_on_shelves.jpg',
                                  size: 29_634,
                                  version: 3,
                                  hasMimeType: 'image/jpeg',
                                  hasMessageDigests: [
                                    {
                                      type: 'sha1',
                                      digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                    },
                                    {
                                      type: 'md5',
                                      digest: '3e9498107f73ff827e718d5c743f8813'
                                    }
                                  ],
                                  access: {
                                    view: 'world',
                                    download: 'world'
                                  },
                                  administrative: {
                                    sdrPreserve: true,
                                    shelve: true,
                                    publish: true
                                  }
                                },
                                {
                                  type: Cocina::Models::ObjectType.file.to_s,
                                  externalIdentifier: 'druid:hj185xx2222/changed_on_shelves.jpg',
                                  label: 'changed on shelves',
                                  filename: 'changed_on_shelves.jpg',
                                  size: 29_634,
                                  version: 3,
                                  hasMimeType: 'image/jpeg',
                                  hasMessageDigests: [
                                    {
                                      type: 'sha1',
                                      digest: '96a32f398e228e8228ad84422941110597e0d87a'
                                    },
                                    {
                                      type: 'md5',
                                      digest: '4f9498107f73ff827e718d5c743f8813'
                                    }
                                  ],
                                  access: {
                                    view: 'world',
                                    download: 'world'
                                  },
                                  administrative: {
                                    sdrPreserve: true,
                                    shelve: true,
                                    publish: true
                                  }
                                },
                                {
                                  type: Cocina::Models::ObjectType.file.to_s,
                                  externalIdentifier: 'druid:hj185xx2222/same_on_shelves.jpg',
                                  label: 'same on shelves',
                                  filename: 'same_on_shelves.jpg',
                                  size: 29_634,
                                  version: 3,
                                  hasMimeType: 'image/jpeg',
                                  hasMessageDigests: [
                                    {
                                      type: 'sha1',
                                      digest: '85a32f398e228e8228ad84422941110597e0d87a'
                                    },
                                    {
                                      type: 'md5',
                                      digest: '3e9498107f73ff827e718d5c743f8813'
                                    }
                                  ],
                                  access: {
                                    view: 'world',
                                    download: 'world'
                                  },
                                  administrative: {
                                    sdrPreserve: true,
                                    shelve: true,
                                    publish: true
                                  }
                                }
                              ]
                            }
                          }
                        ],
                        isMemberOf: [
                          'druid:bc778pm9866'
                        ]
                      })
  end

  before do
    stub_request(:get, "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}.json")
      .to_return(status: 200, body: purl_cocina_object.to_json)
  end

  it 'returns diff' do
    expect(described_class.call(cocina_object:)).to eq(['not_on_shelves.jpg', 'changed_on_shelves.jpg'])
  end

  context 'when PURL is not found' do
    before do
      stub_request(:get, "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}.json")
        .to_return(status: 404)
    end

    it 'returns diff' do
      expect(described_class.call(cocina_object:)).to eq(['not_on_shelves.jpg', 'changed_on_shelves.jpg', 'same_on_shelves.jpg'])
    end
  end

  context 'when PURL returns an error' do
    before do
      stub_request(:get, "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}.json")
        .to_return(status: 500)
    end

    it 'raises an error' do
      expect { described_class.call(cocina_object:) }.to raise_error(DigitalStacksDiffer::Error, 'Unable to fetch cocina object from PURL for hj185xx2222: 500')
    end
  end

  context 'when missing a SHA1' do
    let(:purl_cocina_object) do
      cocina_object.new(structural: {
                          contains: [
                            {
                              type: Cocina::Models::FileSetType.file.to_s,
                              externalIdentifier: 'hj185xx2222_1',
                              label: 'Image 1',
                              version: 3,
                              structural: {
                                contains: [
                                  {
                                    type: Cocina::Models::ObjectType.file.to_s,
                                    externalIdentifier: 'druid:hj185xx2222/only_on_shelves.jpg',
                                    label: 'only on shelves',
                                    filename: 'only_on_shelves.jpg',
                                    size: 29_634,
                                    version: 3,
                                    hasMimeType: 'image/jpeg',
                                    hasMessageDigests: [
                                      {
                                        type: 'md5',
                                        digest: '3e9498107f73ff827e718d5c743f8813'
                                      }
                                    ],
                                    access: {
                                      view: 'world',
                                      download: 'world'
                                    },
                                    administrative: {
                                      sdrPreserve: true,
                                      shelve: true,
                                      publish: true
                                    }
                                  }
                                ]
                              }
                            }
                          ],
                          isMemberOf: [
                            'druid:bc778pm9866'
                          ]
                        })
    end

    it 'raises an error' do
      expect { described_class.call(cocina_object:) }.to raise_error(DigitalStacksDiffer::Error, 'Unable to find sha1 for file druid:hj185xx2222/only_on_shelves.jpg')
    end
  end
end
