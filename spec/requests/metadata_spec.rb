# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  let(:user) { Settings.DOR.SERVICE_USER }
  let(:password) { Settings.DOR.SERVICE_PASSWORD }
  let(:basic_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    object.descMetadata.title_info.main_title = 'Hello'
    allow(Dor).to receive(:find).and_return(object)
  end

  it 'returns the DC xml' do
    get '/v1/objects/druid:mk420bs7601/metadata/dublin_core',
        headers: { 'Authorization' => basic_auth }
    expect(response).to be_successful
    expect(response.body).to include '<dc:title>Hello</dc:title>'
  end
end
