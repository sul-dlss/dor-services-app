# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SdrClient do
  describe '.current_version' do
    subject(:current_version) { described_class.current_version('druid:ab123cd4567') }

    it 'returns the current of the object from SDR' do
      stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
        .to_return(body: '<currentVersion>2</currentVersion>')
      expect(current_version).to eq 2
    end

    context 'when it has the wrong root element' do
      it 'raises an exception' do
        stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
          .to_return(body: '<wrongRoot>2</wrongRoot>')
        expect { current_version }.to raise_error(Exception,
                                                  'Unable to parse XML from SDR current_version API call: <wrongRoot>2</wrongRoot>')
      end
    end

    context 'when it does not contain an Integer as its text' do
      it 'raises an exception' do
        stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
          .to_return(body: '<currentVersion>two</currentVersion>')
        expect { current_version }.to raise_error(Exception,
                                                  'Unable to parse XML from SDR current_version API call: <currentVersion>two</currentVersion>')
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
