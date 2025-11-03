# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::ReleaseInitiate, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Workflow::Service).to receive(:create)
  end

  context 'when the object is an admin policy' do
    let(:object) { build(:admin_policy, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'Admin policy objects are not released'
      expect(Workflow::Service).not_to have_received(:create)
    end
  end

  context 'when the object is not an admin policy' do
    let(:object) { build(:dro, id: druid) }

    it 'creates the workflow' do
      expect(perform).to be_nil # no return state defaults to completed.
      expect(Workflow::Service).to have_received(:create).with(druid: druid, workflow_name: 'releaseWF', version: 1)
    end
  end
end
