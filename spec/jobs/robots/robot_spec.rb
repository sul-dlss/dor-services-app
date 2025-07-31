# frozen_string_literal: true

require 'rails_helper'

# A test robot.
class TestRobot < Robots::Robot
  def initialize
    super('testWF', 'test-step')
  end

  def perform_work; end
end

RSpec.describe Robots::Robot do
  subject(:robot) { TestRobot.new }

  describe '#object_client' do
    it 'raises an error' do
      expect { robot.object_client }.to raise_error(RuntimeError, '.object_client should not be used from a DSA robot')
    end
  end

  describe '#perform' do
    let(:robot_workflow) { instance_double(Robots::Robot::RobotWorkflow, status: 'queued', start!: true, complete!: true) }

    before do
      allow(Robots::Robot::RobotWorkflow).to receive(:new).and_return(robot_workflow)
    end

    it 'invokes a RobotWorkflow' do
      robot.perform('druid:gv054hp4128')
      expect(robot.send(:workflow)).to be robot_workflow
      expect(Robots::Robot::RobotWorkflow).to have_received(:new).with(workflow_name: 'testWF', process: 'test-step',
                                                                       druid: 'druid:gv054hp4128')
      expect(robot_workflow).to have_received(:start!).with(Socket.gethostname)
      expect(robot_workflow).to have_received(:complete!).with('completed', Float, Socket.gethostname)
    end
  end

  describe Robots::Robot::RobotWorkflow do
    subject(:workflow) do
      described_class.new(workflow_name: 'testWF', process: 'test-step', druid: 'druid:gv054hp4128')
    end

    let(:workflow_response) { instance_double(Dor::Workflow::Response::Workflow, process_for_recent_version: process_response) }
    let(:process_response) { instance_double(Dor::Workflow::Response::Process, name: 'test-step', status: 'waiting', lane_id: 'low', context: { foo: 'bar' }) }

    before do
      allow(Workflow::Service).to receive(:workflow).and_return(workflow_response)
      allow(Workflow::ProcessService).to receive(:update)
      allow(Workflow::ProcessService).to receive(:update_error)
    end

    describe '.object_workflow' do
      it 'raises an error' do
        expect { workflow.object_workflow }.to raise_error(RuntimeError)
      end
    end

    describe '.workflow_process' do
      it 'raises an error' do
        expect { workflow.workflow_process }.to raise_error(RuntimeError)
      end
    end

    describe '.workflow_response' do
      it 'returns the workflow response for the given druid and workflow name' do
        expect(workflow.workflow_response).to eq(workflow_response)
        expect(Workflow::Service).to have_received(:workflow).with(druid: 'druid:gv054hp4128', workflow_name: 'testWF')
      end
    end

    describe '.process_response' do
      it 'returns the process response for the given process name' do
        expect(workflow.process_response).to eq(process_response)
        expect(workflow_response).to have_received(:process_for_recent_version).with(name: 'test-step')
      end
    end

    describe '.start!' do
      it 'updates the workflow process status to started' do
        workflow.start!('Starting workflow')
        expect(Workflow::ProcessService).to have_received(:update)
          .with(druid: 'druid:gv054hp4128', workflow_name: 'testWF',
                process: 'test-step', status: 'started', note: 'Starting workflow', elapsed: 1.0)
      end
    end

    describe '.complete!' do
      it 'updates the workflow process status to completed' do
        workflow.complete!('completed', 1.0, 'Workflow completed successfully')
        expect(Workflow::ProcessService).to have_received(:update)
          .with(druid: 'druid:gv054hp4128', workflow_name: 'testWF',
                process: 'test-step', status: 'completed', note: 'Workflow completed successfully', elapsed: 1.0)
      end
    end

    describe '.retrying!' do
      it 'updates the workflow process status to retrying' do
        workflow.retrying!
        expect(Workflow::ProcessService).to have_received(:update)
          .with(druid: 'druid:gv054hp4128', workflow_name: 'testWF',
                process: 'test-step', status: 'retrying', note: nil, elapsed: 1.0)
      end
    end

    describe '.error!' do
      it 'updates the workflow process status to error' do
        workflow.error!('An error occurred', 'Detailed error information')
        expect(Workflow::ProcessService).to have_received(:update_error)
          .with(druid: 'druid:gv054hp4128', workflow_name: 'testWF',
                process: 'test-step', error_msg: 'An error occurred', error_text: 'Detailed error information')
      end
    end

    describe '.status' do
      it 'returns the status of the process response' do
        expect(workflow.status).to eq('waiting')
      end
    end

    describe '.lane_id' do
      it 'returns the lane_id of the process response' do
        expect(workflow.lane_id).to eq('low')
      end
    end

    describe '.context' do
      it 'returns the context of the process response' do
        expect(workflow.context).to eq({ foo: 'bar' })
      end
    end
  end
end
