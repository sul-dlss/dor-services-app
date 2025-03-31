# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::SdrIngestTransfer, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:workflow_service) { instance_double(Dor::Workflow::Client) }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'low') }
  let(:object) { build(:dro, id: druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(PreservationIngestService).to receive(:transfer)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_service)
    allow(workflow_service).to receive(:create_workflow_by_name)
    allow(workflow_service).to receive(:process).and_return(process)
  end

  it 'preserves the object' do
    expect(perform).to be_nil # no return state defaults to completed.
    expect(PreservationIngestService).to have_received(:transfer).with(object)
    expect(workflow_service).to have_received(:create_workflow_by_name).with(druid, 'preservationIngestWF',
                                                                             version: object.version, lane_id: 'low')
  end
end
