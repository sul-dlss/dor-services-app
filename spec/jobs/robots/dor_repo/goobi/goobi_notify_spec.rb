# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Goobi::GoobiNotify, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:fake_request) { "<stanfordCreationRequest><objectId>#{druid}</objectId></stanfordCreationRequest>" }
  let(:object) { build(:dro, id: druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(GoobiService).to receive(:register).and_call_original
  end

  context 'when it is successful' do
    before do
      stub_request(:post, Settings.goobi.url)
        .to_return(body: fake_request,
                   headers: { 'Content-Type' => 'application/xml' },
                   status: 201)
    end

    it 'notifies goobi of a new registration by making a web service call' do
      expect { perform }.not_to raise_error
      expect(GoobiService).to have_received(:register).with(object)
    end
  end

  context 'when it is a conflict' do
    before do
      stub_request(:post, Settings.goobi.url)
        .to_return(body: 'conflict',
                   status: 409)
    end

    it 'raises' do
      expect { perform }.to raise_error(RuntimeError, 'Unexpected response from Goobi (409): conflict')
    end
  end
end
