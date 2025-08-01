# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::SdrIngestTransfer, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:workflow) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process) }
  let(:process) { instance_double(Dor::Services::Response::Process, lane_id: 'low') }
  let(:object) { build(:dro, id: druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(PreservationIngestService).to receive(:transfer)
    allow(Workflow::Service).to receive(:create)
    allow(Workflow::Service).to receive(:workflow).with(druid:,
                                                        workflow_name: 'accessionWF').and_return(workflow)
  end

  it 'preserves the object' do
    expect(perform).to be_nil # no return state defaults to completed.
    expect(PreservationIngestService).to have_received(:transfer).with(object)
    expect(Workflow::Service).to have_received(:create).with(druid:, workflow_name: 'preservationIngestWF',
                                                             version: object.version, lane_id: 'low')
  end
end
