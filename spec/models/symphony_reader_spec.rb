# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyReader do
  subject(:reader) { described_class.new(catkey: catkey) }
  let(:catkey) { 'catkey' }

  describe '#to_marc' do
    before do
      stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: catkey)).to_return(body: body.to_json, headers: headers)
    end

    let(:body) do
      {
        resource: '/catalog/bib',
        key: '111',
        fields: {
          bib: {
            standard: 'MARC21',
            type: 'BIB',
            leader: '00956cem 2200229Ma 4500',
            fields: [
              { tag: '001', subfields: [{ code: '_', data: 'some data' }] },
              { tag: '001', subfields: [{ code: '_', data: 'some other data' }] },
              { tag: '009', subfields: [{ code: '_', data: 'whatever' }] },
              {
                tag: '245',
                inds: '41',
                subfields: [{ code: 'a', data: 'some data' }]
              }
            ]
          }
        }
      }
    end
    let(:headers) { { 'Content-Length': 394 } }

    it 'converts symphony json to marc records' do
      expect(reader.to_marc).to be_a_kind_of MARC::Record
    end

    it 'parses leader information' do
      expect(reader.to_marc.leader).to eq '00956cem 2200229Ma 4500'
    end

    it 'parses control fields' do
      expect(reader.to_marc.fields('009').first.value).to eq 'whatever'
    end

    it 'removes original 001 fields and puts catkey in 001 field' do
      expect(reader.to_marc.fields('001').length).to eq 1
      expect(reader.to_marc.fields('001').first.value).to eq 'acatkey'
    end

    it 'parses data fields' do
      field = reader.to_marc.fields('245').first
      expect(field.indicator1).to eq '4'
      expect(field.indicator2).to eq '1'
      expect(field.subfields.first.code).to eq 'a'
      expect(field.subfields.first.value).to eq 'some data'
    end

    context 'when response is chunked' do
      let(:headers) { { 'Content-Length': 0, 'Transfer-Encoding': 'chunked' } }

      it 'does not validate content length' do
        expect(reader.to_marc).to be_a_kind_of MARC::Record
      end
    end

    describe 'when errors in response from Symphony' do
      context 'when wrong number of bytes received' do
        let(:headers) { { 'Content-Length': 268 } }

        it 'raises ResponseError and notifies Honeybadger' do
          msg = 'Incomplete response received from Symphony for catkey - expected 268 bytes but got 394'
          allow(Honeybadger).to receive(:notify)
          expect { reader.to_marc }.to raise_error(SymphonyReader::ResponseError, msg)
          expect(Honeybadger).to have_received(:notify).with(msg)
        end
      end

      context 'when catkey not found' do
        before do
          stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: catkey)).to_return(status: 404)
        end

        it 'raises ResponseError and does not notify Honeybadger' do
          msg = 'Record not found in Symphony: catkey'
          allow(Honeybadger).to receive(:notify)
          expect { reader.to_marc }.to raise_error(SymphonyReader::ResponseError, msg)
          expect(Honeybadger).not_to have_received(:notify).with(msg)
        end
      end

      context 'when other HTTP error from Symphony' do
        let(:err_body) do
          {
            messageList: [
              {
                code: 'oops',
                message: 'Something somewhere went wrong.'
              }
            ]
          }
        end

        before do
          stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: catkey)).to_return(status: 403, body: err_body.to_json)
        end

        it 'raises ResponseError and notifies Honeybadger' do
          msg_regex = /^Got HTTP Status-Code 403 retrieving catkey from Symphony:.*Something somewhere went wrong./
          allow(Honeybadger).to receive(:notify)
          expect { reader.to_marc }.to raise_error(SymphonyReader::ResponseError, msg_regex)
          expect(Honeybadger).to have_received(:notify).with(msg_regex)
        end
      end

      context 'when Faraday::Timeout' do
        let(:faraday_msg) { 'faraday failed' }

        before do
          stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: catkey)).to_raise(Faraday::TimeoutError.new(faraday_msg))
        end

        it 'raises ResponseError and notifies Honeybadger' do
          msg_regex = /^Timeout for Symphony response for catkey catkey: #{faraday_msg}/
          allow(Honeybadger).to receive(:notify)
          expect { reader.to_marc }.to raise_error(SymphonyReader::ResponseError, msg_regex)
          expect(Honeybadger).to have_received(:notify).with(msg_regex)
        end
      end
    end
  end
end
