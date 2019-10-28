# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when the requested object is an item' do
    let(:object) { Dor::Item.new(pid: 'druid:bb022sv9134') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:bb022sv9134',
          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
          label: 'foo',
          version: 1,
          access: {},
          administrative: {
            releaseTags: []
          },
          identification: {},
          structural: {
            contains: []
          }
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end

    context 'when the object exists with full metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
        object.embargoMetadata.release_date = DateTime.parse '2019-09-26T07:00:00Z'
        object.contentMetadata.content = <<~CONTENT_METADATA
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bb022sv9134" type="book">
            <resource id="bb022sv9134_1" sequence="1" type="page">
              <label>Page 1</label>
              <file id="bb022sv9134_1.tif" preserve="yes" publish="no" shelve="no" mimetype="image/tiff" size="474764">
                <checksum type="md5">17d8f2b5a9a785dc91e5d2aada82ade1</checksum>
                <checksum type="sha1">13b7d3a7484e23f5bdcd351dda1dd9768576d371</checksum>
                <imageData width="1700" height="2152"/>
              </file>
              <file id="bb022sv9134_1.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="8097">
                <checksum type="md5">1cdaaddf395e430f73f7aa29ea2cc3c6</checksum>
                <checksum type="sha1">1cdec77f89e3a50f38f7ee819b2b22584507c1ae</checksum>
              </file>
              <file id="bb022sv9134_1.xml" preserve="yes" publish="yes" shelve="yes" role="transcription" mimetype="application/xml" size="14480">
                <checksum type="md5">d2b0e0830dbe63016417d667512e6c45</checksum>
                <checksum type="sha1">98f259d7148e378e53f9608a24419caa7c2c2308</checksum>
              </file>
              <file id="bb022sv9134_1.jp2" mimetype="image/jp2" size="282047" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">aed68ef2e1533cfd49c987c229428d03</checksum>
                <checksum type="sha1">12c7fbaa54325057ac2dfcc6e43c8366a106f2fd</checksum>
                <imageData width="1700" height="2152"/>
              </file>
            </resource>
            <resource id="bb022sv9134_2" sequence="2" type="page">
              <label>Page 2</label>
              <file id="bb022sv9134_2.tif" preserve="yes" publish="no" shelve="no" mimetype="image/tiff" size="474764">
                <checksum type="md5">d021df0e1d86d65c23370472160209c2</checksum>
                <checksum type="sha1">2f6846ed90adaee2f4ca57d86a724c7d8fb3b6ab</checksum>
                <imageData width="1700" height="2152"/>
              </file>
              <file id="bb022sv9134_2.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="7482">
                <checksum type="md5">1f0caf57513b554c745fc0112055d2a4</checksum>
                <checksum type="sha1">20149dcf3373b6f3e4751ab56ea15fb011fd6d1a</checksum>
              </file>
              <file id="bb022sv9134_2.xml" preserve="yes" publish="yes" shelve="yes" role="transcription" mimetype="application/xml" size="12834">
                <checksum type="md5">3db374bb3694657682c8961180b90b6f</checksum>
                <checksum type="sha1">305ad8aff57ad4b675003e164f5fcc0bdd333f6e</checksum>
              </file>
              <file id="bb022sv9134_2.jp2" mimetype="image/jp2" size="239574" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">ec2cb83d5f174d01844d841118d922cd</checksum>
                <checksum type="sha1">cbf79822292160ed3d9a437c1305c3f34f0a0f47</checksum>
                <imageData width="1700" height="2152"/>
              </file>
            </resource>
          </contentMetadata>
        CONTENT_METADATA
        ReleaseTags.create(object, release: true,
                                   what: 'self',
                                   to: 'Searchworks',
                                   who: 'petucket',
                                   when: '2014-08-30T01:06:28Z')
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:bb022sv9134',
          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
          label: 'foo',
          version: 1,
          access: {
            embargoReleaseDate: '2019-09-26T07:00:00.000+00:00'
          },
          administrative: {
            releaseTags: [
              {
                to: 'Searchworks',
                what: 'self',
                date: '2014-08-30T01:06:28.000+00:00',
                who: 'petucket',
                release: true
              }
            ]
          },
          identification: {},
          structural: {
            contains: %w[bb022sv9134_1 bb022sv9134_2]
          }
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end
  end

  context 'when the requested object is an APO' do
    let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:bb022sv9134') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:bb022sv9134',
          type: 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld',
          label: 'foo',
          version: 1,
          access: {},
          administrative: {},
          identification: {},
          structural: {}
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end
  end
end
