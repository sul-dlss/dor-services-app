# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrAdminPolicyFactory do
  subject(:policy) { described_class.create }

  let(:druid) { Settings.ur_admin_policy.druid }

  before do
    allow(Indexer).to receive(:reindex)
  end

  it 'creates the Ur-AdminPolicy' do
    expect(RepositoryObject.exists?(external_identifier: druid)).to be false
    policy
    expect(RepositoryObject.exists?(external_identifier: druid)).to be true
    expect(Indexer).to have_received(:reindex).with(cocina_object: an_instance_of(Cocina::Models::AdminPolicyWithMetadata))
  end
end
