# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrAdminPolicyFactory do
  subject(:create) { described_class.create }

  let(:druid) { Settings.ur_admin_policy.druid }

  before do
    allow(Notifications::ObjectCreated).to receive(:publish)
  end

  it 'creates the Ur-AdminPolicy' do
    expect(AdminPolicy.exists?(external_identifier: druid)).to be false
    create
    expect(AdminPolicy.exists?(external_identifier: druid)).to be true
    expect(Notifications::ObjectCreated).to have_received(:publish)
  end
end
