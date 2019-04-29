# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  let(:user) { Settings.DOR.SERVICE_USER }
  let(:password) { Settings.DOR.SERVICE_PASSWORD }
  let(:basic_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(RefreshMetadataAction).to receive(:run).and_return('<xml />')
    allow(object).to receive(:save)
  end

  it 'updates the metadata and saves the changes' do
    post '/v1/objects/druid:mk420bs7601/refresh_metadata',
         headers: { 'Authorization' => basic_auth }
    expect(response).to be_successful
    expect(RefreshMetadataAction).to have_received(:run).with(object)
    expect(object).to have_received(:save)
  end
end
