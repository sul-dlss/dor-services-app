# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Preserve object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(PreserveJob).to receive(:perform_later)
  end

  it 'initiates PreserveJob and returns 201' do
    post "/v1/objects/#{druid}/preserve", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(PreserveJob).to have_received(:perform_later).with(druid: druid, background_job_result: BackgroundJobResult)
    expect(response.status).to eq(201)
  end
end
