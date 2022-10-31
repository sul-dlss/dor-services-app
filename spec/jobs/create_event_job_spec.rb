# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateEventJob do
  subject(:perform) { described_class.new.work(msg.to_json) }

  let(:msg) do
    {
      druid:,
      event_type:,
      data:
    }
  end

  let(:druid) { 'druid:bb408qn5061' }

  let(:event_type) { 'druid_version_replicated' }

  let(:data) do
    {
      host: 'preservation-catalog-qa-02.stanford.edu',
      version: 19,
      invoked_by: 'preservation-catalog',
      parts_info: [
        {
          md5: '1a528419dea59d86cfd0c456e9f10024',
          size: 123630,
          s3_key: 'bb/408/qn/5061/bb408qn5061.v0019.zip'
        }
      ],
      endpoint_name: 'aws_s3_east_1'
    }
  end

  before do
    allow(Event).to receive(:create!)
  end

  it 'creates event' do
    perform
    expect(Event).to have_received(:create!).with(druid:, event_type:, data:)
  end
end
