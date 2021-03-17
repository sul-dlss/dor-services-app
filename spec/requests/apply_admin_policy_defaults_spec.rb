# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(object).to receive(:save!)
  end

  let(:object) { Dor::Item.new(admin_policy_object: admin_policy) }
  let(:admin_policy) do
    Dor::AdminPolicyObject.new.tap do |coll|
      coll.defaultObjectRights.content = '<foo/>'
    end
  end

  it 'copies the rights metadata from the AdminPolicy to the object' do
    post '/v1/objects/druid:mk420bs7601/apply_admin_policy_defaults',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(object.rightsMetadata.content).to eq '<foo/>'
    expect(object).to have_received(:save!)
  end
end
