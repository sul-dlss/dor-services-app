# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrAdminPolicyFactory do
  subject(:create) { described_class.create }

  let(:ur_apo) { instance_double(Dor::AdminPolicyObject, save!: true, add_relationship: true) }

  before do
    allow(Dor::AdminPolicyObject).to receive(:exists?).and_return(false)
    allow(Dor::AdminPolicyObject).to receive(:new).and_return(ur_apo)
    allow(ActiveFedora::SolrService).to receive_messages(add: true, commit: true)
  end

  it 'creates the Ur-AdminPolicy' do
    create
    expect(ur_apo).to have_received(:save!)
    expect(ActiveFedora::SolrService).to have_received(:add)
    expect(ActiveFedora::SolrService).to have_received(:commit)
  end
end
