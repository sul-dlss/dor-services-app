# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SdrClient do
  # TODO: Remove this in 4.0.0
  describe '.current_version' do
    subject(:current_version) { described_class.current_version('druid:ab123cd4567') }

    let(:url) { 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version' }
    let(:url_with_basic_auth) { url.sub('http://', 'http://user:password@') }

    it 'returns the current of the object from SDR' do
      stub_request(:get, url)
        .with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNzd29yZA==' })
        .to_return(body: '<currentVersion>2</currentVersion>')
      expect(current_version).to eq 2
    end

    context 'when it has the wrong root element' do
      it 'raises an exception' do
        stub_request(:get, url)
          .to_return(body: '<wrongRoot>2</wrongRoot>')
        expect { current_version }.to raise_error(RuntimeError,
                                                  "Unable to parse XML from SDR current_version API call.\n\turl: #{url_with_basic_auth}\n\tstatus: 200\n\tbody: <wrongRoot>2</wrongRoot>")
      end
    end

    context 'when it does not contain an Integer as its text' do
      it 'raises an exception' do
        stub_request(:get, url)
          .to_return(body: '<currentVersion>two</currentVersion>')
        expect { current_version }.to raise_error(RuntimeError,
                                                  "Unable to parse XML from SDR current_version API call.\n\turl: #{url_with_basic_auth}\n\tstatus: 200\n\tbody: <currentVersion>two</currentVersion>")
      end
    end

    context "when sdr-services-app doesn't know about the object" do
      before do
        stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
          .to_return(status: 404, body: '')
      end

      it 'raises an error' do
        expect { current_version }.to raise_error Dor::Exception
      end
    end
  end
end
