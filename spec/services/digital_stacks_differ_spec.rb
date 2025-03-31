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
                                               digest: '2b9498107f73ff827e718d5c743f8802'
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
                                           hasMessageDigests: not_on_shelves_message_digests,
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
                                               digest: '5g9498107f73ff827e718d5c743f8836'
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

  let(:not_on_shelves_message_digests) do
    [
      {
        type: 'sha1',
        digest: '85a32f398e228e8228ad84422941110597e0d87a'
      },
      {
        type: 'md5',
        digest: '4f9498107f73ff827e718d5c743f8824'
      }
    ]
  end

  let(:purl_files_by_digest) do
    [
      { '9e9498107f73ff827e718d5c743f8819' => 'only_on_shelves.jpg' },
      { '0f9498107f73ff827e718d5c743f8810' => 'changed_on_shelves.jpg' },
      { '3e9498107f73ff827e718d5c743f8813' => 'same_on_shelves.jpg' }
    ]
  end

  let(:purl_fetcher_reader) { instance_double(PurlFetcher::Client::Reader, files_by_digest: purl_files_by_digest) }

  before do
    allow(PurlFetcher::Client::Reader).to receive(:new)
      .with(host: Settings.purl_fetcher.url).and_return(purl_fetcher_reader)
  end

  it 'returns diff' do
    expect(described_class.call(cocina_object:)).to eq(['not_on_shelves.jpg', 'changed_on_shelves.jpg'])
    expect(purl_fetcher_reader).to have_received(:files_by_digest).with(druid.delete_prefix('druid:'))
  end

  context 'when PURL is not found' do
    before do
      allow(purl_fetcher_reader).to receive(:files_by_digest).and_raise(PurlFetcher::Client::NotFoundResponseError)
    end

    it 'returns diff' do
      expect(described_class.call(cocina_object:)).to eq(['not_on_shelves.jpg', 'changed_on_shelves.jpg',
                                                          'same_on_shelves.jpg'])
    end
  end

  context 'when PURL returns an error' do
    before do
      allow(purl_fetcher_reader).to receive(:files_by_digest).and_raise(PurlFetcher::Client::ResponseError)
    end

    it 'raises an error' do
      expect { described_class.call(cocina_object:) }.to raise_error(DigitalStacksDiffer::Error)
    end
  end

  context 'when missing a SHA1' do
    let(:not_on_shelves_message_digests) do
      [
        {
          type: 'sha1',
          digest: '85a32f398e228e8228ad84422941110597e0d87a'
        }
      ]
    end

    it 'raises an error' do
      expect do
        described_class.call(cocina_object:)
      end.to raise_error(DigitalStacksDiffer::Error,
                         'Unable to find md5 for file druid:hj185xx2222/not_on_shelves.jpg')
    end
  end
end
