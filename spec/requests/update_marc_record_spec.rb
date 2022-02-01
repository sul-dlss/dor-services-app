# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MARC record' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A generic label',
                            version: 1,
                            description: build_cocina_description_metadata_1(druid),
                            identification: {},
                            access: {},
                            administrative: { hasAdminPolicy: 'druid:pp000pp0000' })
  end

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
  end

  context 'when the request is successful' do
    it 'returns a 201 response' do
      post "/v1/objects/#{druid}/update_marc_record", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(201)
    end
  end
end
