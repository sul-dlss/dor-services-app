# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset workspace' do
  let(:druid) { 'druid:bb222cc3333' }

  before do
    allow(CocinaObjectStore).to receive(:version).and_return(2)
    allow(ResetWorkspaceJob).to receive(:perform_later)
  end

  context 'when the request is succcessful' do
    it 'is successful' do
      post "/v1/objects/#{druid}/workspace/reset", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(ResetWorkspaceJob).to have_received(:perform_later).with(druid:, version: 2)
      expect(response).to be_no_content
    end
  end
end
