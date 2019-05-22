# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SdrClient do
  describe '.current_version' do
    it 'returns the current of the object from SDR' do
      stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
        .to_return(body: '<currentVersion>2</currentVersion>')
      expect(described_class.current_version('druid:ab123cd4567')).to eq 2
    end

    context 'when it has the wrong root element' do
      it 'raises an exception' do
        stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
          .to_return(body: '<wrongRoot>2</wrongRoot>')
        expect { described_class.current_version('druid:ab123cd4567') }
          .to raise_error(Exception, 'Unable to parse XML from SDR current_version API call: <wrongRoot>2</wrongRoot>')
      end
    end

    context 'when it does not contain an Integer as its text' do
      it 'raises an exception' do
        stub_request(:get, 'http://sdr-services.example.com/sdr/objects/druid:ab123cd4567/current_version')
          .to_return(body: '<currentVersion>two</currentVersion>')
        expect { described_class.current_version('druid:ab123cd4567') }
          .to raise_error(Exception, 'Unable to parse XML from SDR current_version API call: <currentVersion>two</currentVersion>')
      end
    end
  end

  describe '.create' do
    context 'with SDR configuration' do
      before do
        allow(Settings).to receive(:sdr_url).and_return('http://example.com')
      end

      it 'is configured to use SDR' do
        expect(described_class.create.url).to eq 'http://example.com'
      end
    end
  end
end
